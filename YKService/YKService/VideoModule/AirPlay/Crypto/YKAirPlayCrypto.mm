//
//  YKAirPlayCrypto.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/22.
//


extern "C" {
#import "playfair.h"
}

#import "aes.h"
#import "modes.h"
#import "osrng.h"
#import "secblock.h"
#import "xed25519.h"
#import "YKServiceLogger.h"
#import "YKAirPlayCrypto.h"

typedef struct YKAirPlayH264CCD
{
    const uint8_t version;
    const uint8_t profileHigh;
    const uint8_t compatibility;
    const uint8_t level;
    const uint8_t reserved6andNAL;
    const uint8_t reserved3andSPS;
private:
    uint16_t lenofSPS;
    
    //--------------------
public:

    uint8_t GetNal() {
        return reserved6andNAL & 0b11;
    }

    uint8_t GetNumberOfSPS() {
        return reserved3andSPS & 0b11111;
    }

    uint16_t GetLenOfSPS() const {
        return ntohs(lenofSPS);
    }

    uint8_t* GetSequence() const {
        return (uint8_t*)&lenofSPS + sizeof(lenofSPS);
    }

    //picture parameter set
    uint8_t GetNumberOfPPS() const {
        return *(GetSequence() + GetLenOfSPS());
    }

    uint16_t GetLenOfPPS() const {
        return ntohs(*(uint16_t*)(GetSequence() + GetLenOfSPS() + 1));
    }

    uint8_t* GetPPS() const {
        return (GetSequence() + GetLenOfSPS() + 1 + 2);
    }
} *PYKAirPlayH264CCD;



using namespace CryptoPP;

@interface YKAirPlayCrypto()
{
    ed25519::Signer m_edSigner;
    SecByteBlock m_pairAesKey;
    SecByteBlock m_pairAesIV;
    SecByteBlock m_ecdhPubKeyPhone;
    SecByteBlock m_edPubKeyPhone;
    SecByteBlock m_ecdhSharedKey;
    SecByteBlock m_ecdhPriKeyServer;
    
    SecByteBlock m_strAesKey;//SETUP1 步骤解密的key
    AutoSeededRandomPool prng;
    
    CTR_Mode<CryptoPP::AES>::Decryption m_AesCtrDec;//视频解密
}
@end

@implementation YKAirPlayCrypto

-(instancetype)init {
    self = [super init];
    if (self) {
        
        m_edSigner.AccessPrivateKey().GenerateRandom(prng);
    }
    return self;
}


#pragma mark - 生成pairSetup 公钥
-(NSData *)pairSetupPublic {
    
    ed25519::Verifier verifier(m_edSigner);
    const ed25519PublicKey& pubKey = dynamic_cast<const ed25519PublicKey&>(verifier.GetPublicKey());
    return [[NSData alloc] initWithBytes:pubKey.GetPublicKeyBytePtr() length:ed25519PublicKey::PUBLIC_KEYLENGTH];
}

#pragma mark - 验签pairVerify 步骤1
-(NSData *)pairVerifySign1:(NSData *)data {
    
    unsigned char* pData = (unsigned char*)data.bytes;
    
    m_ecdhPubKeyPhone.Assign(pData, x25519::PUBLIC_KEYLENGTH);
    m_edPubKeyPhone.Assign(pData + x25519::PUBLIC_KEYLENGTH, ed25519PublicKey::PUBLIC_KEYLENGTH);
    
    m_ecdhPriKeyServer.resize(x25519::SECRET_KEYLENGTH);
    m_ecdhSharedKey.resize(x25519::SHARED_KEYLENGTH);
    
    SecByteBlock ecdhPublicKey(x25519::PUBLIC_KEYLENGTH);
    
    x25519 x25519;
    x25519.GenerateKeyPair(prng, m_ecdhPriKeyServer, ecdhPublicKey);
    
    
    x25519.Agree(m_ecdhSharedKey, m_ecdhPriKeyServer, m_ecdhPubKeyPhone);
    
    
    SecByteBlock message = ecdhPublicKey;
    message += m_ecdhPubKeyPhone;
    
    
    SecByteBlock signature(ed25519::Signer::SIGNATURE_LENGTH);
    m_edSigner.SignMessage(prng, message, message.size(), signature);
    
    
    {
        const std::basic_string_view<unsigned char> keySalt = (unsigned char*)"Pair-Verify-AES-Key";
        SHA512 hash;
        hash.Update(keySalt.data(), keySalt.size());
        hash.Update(m_ecdhSharedKey, m_ecdhSharedKey.size());
        
        m_pairAesKey.resize(SHA512::DIGESTSIZE);
        hash.Final(m_pairAesKey);
    }
    {
        const std::basic_string_view<unsigned char> ivSalt = (unsigned char*)"Pair-Verify-AES-IV";
        SHA512 hash;
        hash.Update(ivSalt.data(), ivSalt.size());
        hash.Update(m_ecdhSharedKey, m_ecdhSharedKey.size());
        
        m_pairAesIV.resize(SHA512::DIGESTSIZE);
        hash.Final(m_pairAesIV);
    }
    
    
    std::string strAesSignature;
    @try {
        CTR_Mode<AES>::Encryption encryptionPair;
        encryptionPair.SetKeyWithIV(m_pairAesKey, AES::DEFAULT_KEYLENGTH, m_pairAesIV);
        
        StringSource(signature, signature.size(), true,
                     new StreamTransformationFilter(encryptionPair,
                                                    new StringSink(strAesSignature)
                                                    )
                     );
    } @catch (NSException *exception) {
        LOGI(@"验签pairVerify 步骤1 错误: %@",exception);
    } @finally {
        
        NSMutableData *result = [[NSMutableData alloc] init];
        NSData *ecdhPublicKeyData = [[NSData alloc] initWithBytes:ecdhPublicKey.data() length:ecdhPublicKey.size()];
        [result appendData:ecdhPublicKeyData];
        NSData *strAesSignatureData = [[NSData alloc] initWithBytes:strAesSignature.data() length:strAesSignature.size()];
        [result appendData:strAesSignatureData];
        return result;
    }
    return nil;
}

#pragma mark - 验签pairVerify 步骤2
-(BOOL)pairVerifySign2:(NSData *)data {
    
    SecByteBlock signature;
    signature.Assign((unsigned char*)data.bytes, 64);
    
    SecByteBlock messageSig(ed25519::Verifier::SIGNATURE_LENGTH);
    std::string strOut;
    
    CTR_Mode<AES>::Encryption encryptionPair;
    encryptionPair.SetKeyWithIV(m_pairAesKey, AES::DEFAULT_KEYLENGTH, m_pairAesIV);
    
    @try {
        encryptionPair.ProcessData(messageSig, messageSig, messageSig.size());
        encryptionPair.ProcessData(messageSig, signature, signature.size());
    } @catch (NSException *exception) {
        LOGI(@"验签pairVerify 步骤2 错误: %@",exception);
    } @finally {
        
        auto message = m_ecdhPubKeyPhone;
        {
            x25519 x25519;
            SecByteBlock ecdhPublicKey(x25519::PUBLIC_KEYLENGTH);
            x25519.GeneratePublicKey(prng, m_ecdhPriKeyServer, ecdhPublicKey);
            message += ecdhPublicKey;
        }
        
        ed25519::Verifier verifier(m_edPubKeyPhone);
        if (verifier.VerifyMessage(message, message.size(), messageSig, messageSig.size()))
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
}


#pragma mark - 获取SETUP1  AES Key密钥
-(void)SETUP1:(NSData *)datFairPlay ekey:(NSData *)ekey {
    
    m_strAesKey.resize(AES::DEFAULT_KEYLENGTH);
    playfair_decrypt((unsigned char*)datFairPlay.bytes, (unsigned char*)ekey.bytes, m_strAesKey.data());
}

#pragma mark - 解密镜像
-(BOOL)mirrorDecode:(uint64_t)streamConnectionID
{
    if (m_strAesKey.empty())
        return false;
    
    NSData * strToHashKey = [[NSString stringWithFormat:@"%@%llu",@"AirPlayStreamKey",streamConnectionID] dataUsingEncoding:NSUTF8StringEncoding];
    NSData * strToHashIV = [[NSString stringWithFormat:@"%@%llu",@"AirPlayStreamIV",streamConnectionID] dataUsingEncoding:NSUTF8StringEncoding];
    
    SecByteBlock eAesKey(SHA512::DIGESTSIZE);
    SecByteBlock realAesKey(SHA512::DIGESTSIZE);
    SecByteBlock realAesIV(SHA512::DIGESTSIZE);
    
    {
        SHA512 hash;
        hash.Update(m_strAesKey, 16);
        hash.Update(m_ecdhSharedKey.data(), m_ecdhSharedKey.size());
        hash.Final(eAesKey);
    }
    
    {
        SHA512 hash;
        hash.Update((byte*)strToHashKey.bytes, strToHashKey.length);
        hash.Update(eAesKey, 16);
        hash.Final(realAesKey);
    }
    
    {
        SHA512 hash;
        hash.Update((byte*)strToHashIV.bytes, strToHashIV.length);
        hash.Update(eAesKey, 16);
        hash.Final(realAesIV);
    }
    
    m_AesCtrDec.SetKeyWithIV(realAesKey, 16, realAesIV, 16);
    return true;
}

#pragma mark - 镜像SPSPPS数据解密
-(NSData *)mirrorSPSPPSDataDecode:(NSData *)data {
    
    auto pData = (PYKAirPlayH264CCD)(data.bytes);
    
    std::string datSpsPps(pData->GetLenOfSPS() + pData->GetLenOfPPS() + 8, 0);
    datSpsPps[3] = 1;
    memcpy(datSpsPps.data() + 4, pData->GetSequence(), pData->GetLenOfSPS());
    datSpsPps[pData->GetLenOfSPS() + 4 + 3] = 1;
    memcpy(datSpsPps.data() + 4 + pData->GetLenOfSPS() + 4, pData->GetPPS(), pData->GetLenOfPPS());
    return [[NSData alloc] initWithBytes:datSpsPps.data() length:datSpsPps.size()];
}

#pragma mark - 解密镜像数据
-(NSData *)mirrorDataDecode:(NSData *)data
{
    std::string payload((char *)data.bytes, data.length);
    std::string payloadDecrypted;
    @try {
        StringSource(payload, true,new StreamTransformationFilter(m_AesCtrDec,new StringSink(payloadDecrypted)));
    } @catch (NSException *exception) {
        LOGI(@"解密失败%@",exception);
    } @finally {
        
        const int iBE1 = 0x01000000;
        size_t nNaluSize = 0;
        size_t nNalusCount = 0;
        
        // // 看起来 AirPlay 协议会在 NAL 前加上其大小，我们将其替换为 NAL 字节流格式的 4 字节起始码。
        while (nNaluSize < payload.size())
        {
            
            auto& val = *(u_long*)(payloadDecrypted.data() + nNaluSize);
            int nc_len = ntohl(val);
            
            if (nc_len < 1)
            {
                break;
            }
            memcpy(payloadDecrypted.data() + nNaluSize, &iBE1, 4);
            nNaluSize += nc_len + 4;
            nNalusCount++;
        }
        return [[NSData alloc] initWithBytes:payloadDecrypted.data() length:payloadDecrypted.size()];
    }
}
@end
