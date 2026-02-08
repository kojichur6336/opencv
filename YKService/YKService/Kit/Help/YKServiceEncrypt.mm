//
//  YKServiceEncrypt.m
//  YKService
//
//  Created by liuxiaobin on 2025/12/1.
//  编译:https://github.com/LiuSky/openssl-apple


#import <openssl/evp.h>
#import <openssl/aes.h>
#import <openssl/rand.h>
#import "YKServiceLogger.h"
#import "YKServiceEncrypt.h"


#define yk_sharedInstanceEncrypt                      Ae7ffcg44e80219f5a39c78891cc9bae243
#define yk_srand                                      B7da27dd2xc5c1cb06ed3b4d63e0017467d
#define yk_rand                                       Cc87272xb6cac7fb7806e4bf2a3da359915
#define yk_configKey                                  D3f2xc089dbd47ef0945b656b6a1a8a91b8
#define yk_seedState                                  E2db2404b0f2x26968a196eb5f11709e06c
#define yk_keyTable                                   Fb18dd027b2eb6177056be8412593c7a0c5
#define yk_aesDecryptGCMWithCipherData                Gbf6ad2xca27edf4b51746fb01e880fd4f1
#define yk_aesEncryptGCMWithCipherData                Hedf02e21847df379392cef395ce8c31769


// 随机种子
static const uint32_t YK_random_seed = 0x6D2B79F5;
// 密钥数量
static const int YK_key_count = 4096;
// 混淆掩码
static const uint16_t  YK_OBFUSCATE_MASK = 0xA55A;


@interface YKServiceEncrypt()
@property(nonatomic, strong) NSMutableArray<NSData *> *yk_keyTable;
@property(nonatomic, assign) uint32_t yk_seedState;
@end


@implementation YKServiceEncrypt

+(instancetype)yk_sharedInstanceEncrypt {
    
    static YKServiceEncrypt *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        self.yk_keyTable = [[NSMutableArray alloc] initWithCapacity:YK_key_count];
        [self yk_configKey];
    }
    return self;
}

#pragma mark - 设置伪随机数生成器的种子
-(void)yk_srand:(uint32_t)seed {
    self.yk_seedState = seed;
}

#pragma mark - 生成伪随机数
-(int)yk_rand {
    
    // 使用线性同余生成器公式更新种子状态：下一状态 = (a * 当前状态 + c) % m
    self.yk_seedState = self.yk_seedState * 214013 + 2531011;
    // 通过位移和掩码获取一个伪随机数的低 15 位
    return (self.yk_seedState >> 16) & 0x7FFF;
}

#pragma mark - 配置Key
-(void)yk_configKey {
    
    [self yk_srand:YK_random_seed];
    
    // 生成密钥
    for (int i = 0; i < YK_key_count; ++i) {
        NSMutableData *key = [NSMutableData dataWithLength:16]; // 每个密钥 16 字节
        unsigned char *p = (unsigned char *)key.mutableBytes;
        for (int j = 0; j < 16; ++j) {
            p[j] = (unsigned char)([self yk_rand] & 0xFF); // 填充 16 个字节
        }
        [self.yk_keyTable addObject:key];
    }
}


#pragma mark - 解密数据
-(NSData *)yk_aesDecryptGCMWithCipherData:(NSData *)data {
    
    // 1. 校验长度：2(Index) + 12(IV) + 16(Tag) = 30
    if (data.length < 30) return nil;
    
    // 2.获取存储的值 (前 2 字节表示存储的值)
    uint16_t storedValue;
    [data getBytes:&storedValue length:2];
    
    // 3.提取 IV (初始化向量)，从第 2 字节开始，长度为 12 字节
    NSData *iv = [data subdataWithRange:NSMakeRange(2, 12)];
    uint16_t ivPart;
    [iv getBytes:&ivPart length:2];
    
    // 4.通过存储的值与 IV 部分计算密钥的索引
    uint16_t keyIndex = (storedValue - ivPart) ^ YK_OBFUSCATE_MASK;
    
    // 5.索引越界，说明数据损坏或被篡改
    if (keyIndex >= self.yk_keyTable.count) return nil;
    
    // 6.根据计算的索引获取密钥
    NSData *key = self.yk_keyTable[keyIndex];
    
    // 7.提取 Tag（16 字节），并获取密文体（从第 14 字节开始）
    NSData *tag = [data subdataWithRange:NSMakeRange(data.length - 16, 16)];
    NSData *cipherBody = [data subdataWithRange:NSMakeRange(14, data.length - 30)];
    
    // 创建解密上下文
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx) return nil;  // 如果上下文创建失败，返回 nil
    
    // 初始化解密操作，设置加密算法为 aes_128_gcm
    if (EVP_DecryptInit_ex(ctx, EVP_aes_128_gcm(), NULL, NULL, NULL) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return nil;
    }
    
    // 设置 GCM 模式的 IV 长度为 12 字节
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, (int)iv.length, NULL) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return nil;
    }
    
    // 初始化解密操作，使用密钥和 IV
    if (EVP_DecryptInit_ex(ctx, NULL, NULL, (const unsigned char *)key.bytes, (const unsigned char *)iv.bytes) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return nil;
    }
    
    // 创建一个空的 mutableData 用于存储解密后的明文
    NSMutableData *plainText = [NSMutableData dataWithLength:cipherBody.length];
    int len = 0, plainLen = 0;
    
    // 解密更新过程：将密文解密为明文
    if (EVP_DecryptUpdate(ctx, (unsigned char *)plainText.mutableBytes, &len, (const unsigned char *)cipherBody.bytes, (int)cipherBody.length) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return nil;
    }
    plainLen = len; // 保存解密后的长度
    
    // 设置 GCM 模式的 Tag，用于校验
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, (void *)tag.bytes) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return nil;
    }
    
    // 最后一步解密操作：完成解密并返回明文
    if (EVP_DecryptFinal_ex(ctx, (unsigned char *)plainText.mutableBytes + len, &len) != 1) {
        EVP_CIPHER_CTX_free(ctx);  // 释放上下文
        return nil;  // 解密失败，返回 nil
    }
    plainLen += len;  // 更新明文长度
    
    // 释放上下文
    EVP_CIPHER_CTX_free(ctx);
    
    // 调整明文大小，并返回解密后的数据
    [plainText setLength:plainLen];
    return plainText;
}

#pragma mark - 加密
-(NSData *)yk_aesEncryptGCMWithCipherData:(NSData *)plainText {
    
    // 检查输入的明文长度
    if (plainText.length == 0) {
        return nil;
    }
    
    // 随机选择密钥索引
    uint16_t keyIndex = arc4random_uniform(YK_key_count);
    NSData *key = self.yk_keyTable[keyIndex];
    
    // 检查密钥长度（确保是16字节）
    if (key.length != 16) {
        return nil;
    }
    
    // 生成随机的 IV (12 字节)
    NSMutableData *iv = [NSMutableData dataWithLength:12];
    OSStatus status = SecRandomCopyBytes(kSecRandomDefault, 12, iv.mutableBytes);
    
    // 检查返回值是否为成功
    if (status != errSecSuccess) {
        return nil; // 或者根据需求处理错误
    }
    
    // 计算 IV 的一部分，用于计算存储的值
    uint16_t ivPart;
    [iv getBytes:&ivPart length:2];
    
    // 计算存储的值
    uint16_t storedValue = (keyIndex ^ YK_OBFUSCATE_MASK) + ivPart;
    
    // 创建 OpenSSL 上下文
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        return nil;
    }
    
    // 初始化加密操作，使用 AES-128-GCM
    if (EVP_EncryptInit_ex(ctx, EVP_aes_128_gcm(), NULL, NULL, NULL) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return nil;
    }
    
    // 设置 GCM 模式的 IV 长度为 12 字节
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, (int)iv.length, NULL) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return nil;
    }
    
    // 初始化加密操作，使用密钥和 IV
    if (EVP_EncryptInit_ex(ctx, NULL, NULL, (const unsigned char *)key.bytes, (const unsigned char *)iv.bytes) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return nil;
    }
    
    // 创建一个空的 mutableData 用于存储加密后的密文
    NSMutableData *cipherBody = [NSMutableData dataWithLength:plainText.length];
    int len = 0;

    // 加密更新过程：将明文加密为密文
    if (EVP_EncryptUpdate(ctx, (unsigned char *)cipherBody.mutableBytes, &len, (const unsigned char *)plainText.bytes, (int)plainText.length) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return nil;
    }
    
    // 最后一步加密操作
    int finalLen = 0;
    if (EVP_EncryptFinal_ex(ctx, (unsigned char *)cipherBody.mutableBytes + len, &finalLen) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return nil;
    }
    
    
    // 获取 GCM 模式的 Tag（16 字节）
    NSMutableData *tag = [NSMutableData dataWithLength:16];
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, tag.mutableBytes) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return nil;
    }

    // 调整密文大小
    [cipherBody setLength:len + finalLen];

    // 释放上下文
    EVP_CIPHER_CTX_free(ctx);

    // 构造最终结果：存储的值、IV、密文和 Tag
    NSMutableData *result = [NSMutableData data];
    [result appendBytes:&storedValue length:sizeof(storedValue)];
    [result appendData:iv];
    [result appendData:cipherBody];
    [result appendData:tag];
    
    // 返回加密结果
    return result;
}


#pragma mark - 加密
+(NSData *)yk_aesEncrypt:(NSData *)data {
    return [YKServiceEncrypt.yk_sharedInstanceEncrypt yk_aesEncryptGCMWithCipherData:data];
}

#pragma mark - 解密
+(NSData *)yk_aesDecrypt:(NSData *)data {
    return [YKServiceEncrypt.yk_sharedInstanceEncrypt yk_aesDecryptGCMWithCipherData:data];
}

@end
