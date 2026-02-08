//
//  YKZipMananger.m
//  YKZip
//
//  Created by xiaobin liu on 2024/10/30.
//


#import <string>
#import <zlib.h>
#import "iconv.h"
#import "mz_os.h"
#import "mz_zip.h"
#import <stdio.h>
#import <errno.h>
#import <unistd.h>
#import <dirent.h>
#import <sys/stat.h>
#import "mz_compat.h"
#import <sys/types.h>
#import "YKZipManager.h"
#import "SSZipArchive.h"


#define MAX_PATH 1024
#define MAKE_DIR(path)  mkdir(path, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);


#pragma mark - 打开资源文件
BOOL YKZipManager::open(const char *lpszZipFilePathName, const char *lpszPrefixPath, const char *passwd)
{
    unzFile uf = unzOpen64(lpszZipFilePathName);
    
    if (uf == NULL)
    {
        return NO;
    }
    
    if (passwd != NULL)
    {
        // 如果密码不为空的话，就传进去解密
        bool result = unzOpenCurrentFilePassword(uf, passwd);
        if (result != UNZ_OK) {
            return NO;
        }
    }
    
    m_Handle = uf;
    BOOL result = extractFileList(m_FileInfoMap, lpszPrefixPath);
    return result;
}

#pragma mark - 关闭
BOOL YKZipManager::close()
{
    if(m_Handle)
    {
        unzClose(m_Handle);
        m_Handle = NULL;
    }
    
    return YES;
}


#pragma mark - 从压缩文件中提取指定的文件到目标文件夹
BOOL YKZipManager::extract(const char *lpszExtractFileName, const char *lpszDestFolder, BOOL bIsIgnorePathInZip)
{
    // 检查 ZIP 文件句柄是否有效
    if(m_Handle == NULL)
        return NO; // 如果句柄无效，返回 NO
    
    // 创建目标文件夹（如果不存在的话）
    if (createDirectoriesRecursively(lpszDestFolder) == NO) {
        //创建文件失败
        return NO;
    }
    
    
    // 获取提取文件名的长度
    size_t iLength = strlen(lpszExtractFileName);
    
    // 检查提取文件名是否有效且不包含通配符（* 或 ?）
    if(iLength > 0 && strcspn(lpszExtractFileName, "*?") >= iLength)
    {
        // 在文件信息映射表中查找指定的文件名
        auto iterFileName = m_FileInfoMap.find(lpszExtractFileName);
        
        // 如果找到了该文件名，执行提取操作
        if(iterFileName != m_FileInfoMap.end())
        {
            // 提取指定位置的文件
            return zipExtract((void*)(&(iterFileName->second.m_PositionInZip)), lpszDestFolder, bIsIgnorePathInZip);
        }
        else
            return NO; // 文件未找到，返回 NO
    }
    else
    {
        // 初始化提取计数
        int iExtracted = 0;
        
        // 遍历文件信息映射表
        for(auto iterFileName = m_FileInfoMap.begin(); iterFileName != m_FileInfoMap.end(); iterFileName++)
        {
            // 检查当前文件名是否与提取文件名匹配
            if(iLength == 0 || fileNameWildCompare(lpszExtractFileName, iterFileName->second.m_szFileName.c_str()))
            {
                // 提取匹配的文件
                if(zipExtract((void*)(&(iterFileName->second.m_PositionInZip)), lpszDestFolder, bIsIgnorePathInZip))
                    iExtracted++; // 增加提取计数
            }
        }
        return (BOOL)iExtracted; // 返回成功提取的文件数量
    }
    
    return YES; // 默认返回 YES，表示成功
}

#pragma mark - 从压缩文件中提取指定的文件到内存中的字节数组
BOOL YKZipManager::extract(const char *lpszExtractFileName, std::vector<unsigned char> &rData)
{
    // 检查 ZIP 文件句柄是否有效
    if (m_Handle == NULL)
        return NO;  // 如果无效，返回 NO
    
    // 在文件信息映射表中查找指定的文件名
    auto iterFileName = m_FileInfoMap.find(lpszExtractFileName);
    if (iterFileName != m_FileInfoMap.end())
    {
        // 获取当前 ZIP 文件句柄
        unzFile uf = m_Handle;
        
        // 获取文件在 ZIP 文件中的位置
        unz64_file_pos *pPosition = (unz64_file_pos *)(&(iterFileName->second.m_PositionInZip));
        // 定位到文件位置
        unzGoToFilePos64(uf, pPosition);
        
        char szFilePathA[MAX_PATH];  // 用于存储文件路径
        unz_file_info64 FileInfo;     // 用于存储文件信息
        
        // 获取当前文件的信息，包括文件名和解压后的大小
        if (unzGetCurrentFileInfo64(uf, &FileInfo, szFilePathA, sizeof(szFilePathA), NULL, 0, NULL, 0) != UNZ_OK)
        {
            return NO;  // 如果获取失败，返回 NO
        }
        
        // 打开当前文件以便读取
        if (unzOpenCurrentFile(uf) != UNZ_OK)
        {
            return NO;  // 如果打开失败，返回 NO
        }
        
        // 根据文件的未压缩大小调整 rData 的大小
        rData.resize(FileInfo.uncompressed_size);
        
        // 检查未压缩大小是否超出 uint32_t 范围
        if (FileInfo.uncompressed_size > UINT32_MAX) {
            unzCloseCurrentFile(uf);  // 关闭当前文件
            return NO;  // 超出范围，返回 NO
        }
        
        // 将未压缩大小转换为 uint32_t
        uint32_t uncompressedSize = static_cast<uint32_t>(FileInfo.uncompressed_size);
        
        // 读取当前文件的内容到 rData 中
        size_t bytesRead = unzReadCurrentFile(uf, &(rData[0]), uncompressedSize);
        
        // 检查读取操作是否成功
        if (bytesRead != uncompressedSize) {
            unzCloseCurrentFile(uf);  // 关闭当前文件
            return NO;  // 读取不完整，返回 NO
        }
        
        // 关闭当前文件以释放资源
        unzCloseCurrentFile(uf);
        
        return YES;  // 提取成功，返回 YES
    }
    else {
        return NO;  // 如果文件名未找到，返回 NO
    }
    
}

#pragma mark - Zip压缩
BOOL YKZipManager::createZipFileAtPath(NSString *path, NSString *directoryPath, bool keepParentDirectory, NSString *password)
{
    return [SSZipArchive createZipFileAtPath:path withContentsOfDirectory:directoryPath keepParentDirectory:keepParentDirectory withPassword:password];
}

#pragma mark - zip解压
BOOL YKZipManager::unzipFileAtPath(NSString *path, NSString *destination, NSString *password)
{
    NSError *error;
    return [SSZipArchive unzipFileAtPath:path toDestination:destination overwrite:YES password:password error:&error];
}



//============================================================
// 私有函数
//============================================================
BOOL YKZipManager::extractFileList(FileInfoMap &rMap, const char *lpszPrefixPath)
{
    unzFile uf = m_Handle;
    
    // ZIP 文件中的文件信息结构
    unz_file_info64 FileInfo;
    unz64_file_pos FilePos;
    char lpszFileName[4096], lpszExtraField[2048], lpszComment[2048];
    
    // 定位到第一个文件并清空输出映射表
    if (unzGoToFirstFile(uf) != UNZ_OK) {
        return NO;
    }
    rMap.clear();
    
    do
    {
        // 获取当前文件在 ZIP 文件中的位置信息
        if (unzGetFilePos64(uf, &FilePos) != UNZ_OK) {
            break;
        }
        
        // 获取当前文件的信息（包括文件名、额外字段和注释）
        if (unzGetCurrentFileInfo64(uf, &FileInfo, lpszFileName, sizeof(lpszFileName), lpszExtraField,
                                    sizeof(lpszExtraField), lpszComment, sizeof(lpszComment)) != UNZ_OK) {
            break;
        }
        
        // 初始化文件信息块
        FileInfoBlock oFileInfoBlk;
        oFileInfoBlk.m_szRelativePath = "";
        oFileInfoBlk.m_szFileName = lpszFileName;
        
        // 检查文件路径并将其拆分为目录路径和文件名
        if (char *lpszDirPosition = strrchr(lpszFileName, '/')) {
            *lpszDirPosition = '\0';  // 将目录路径与文件名分隔
            oFileInfoBlk.m_szRelativePath = lpszFileName;
            oFileInfoBlk.m_szFileName = lpszDirPosition + 1;
        }
        
        // 将文件位置复制到文件信息块中
        memcpy(&oFileInfoBlk.m_PositionInZip, &FilePos, sizeof(oFileInfoBlk.m_PositionInZip));
        
        // 如果提供了前缀路径，则检查前缀是否匹配
        if (lpszPrefixPath && strcasecmp(lpszPrefixPath, oFileInfoBlk.m_szRelativePath.c_str()) != 0) {
            continue;  // 如果前缀不匹配，跳过该文件
        }
        
        // 将文件信息存入映射表，使用相对路径和文件名组合作为键
        std::string filePath = oFileInfoBlk.m_szRelativePath.empty()
        ? oFileInfoBlk.m_szFileName
        : oFileInfoBlk.m_szRelativePath + '/' + oFileInfoBlk.m_szFileName;
        
        rMap[filePath] = oFileInfoBlk;
        
    } while (unzGoToNextFile(uf) == UNZ_OK);  // 遍历到下一个文件
    
    // 重置 ZIP 文件指针到第一个文件
    unzGoToFirstFile(uf);
    
    return YES;
}

#pragma mark - 获取IPA里面对应的名称Payload/XXX.app/ 就是要动态获取到这个XXX名称
NSString * YKZipManager::getIPAName()
{
    auto it = m_FileInfoMap.begin();
    for (; it != m_FileInfoMap.end(); it++) {
        auto appPath = it->first.find(".app/");
        if (appPath != -1)
        {
           auto index = it->first.find("/");
            if (index != -1) {
               auto result = it->first.substr(index + 1, appPath - index - 1);
                return [[NSString alloc] initWithUTF8String:result.data()];
            }
        }
    }
    return nil;
}

#pragma mark - 解压指定文件到指定目录
BOOL YKZipManager::extractFileAtPathFromIPA(NSString *path, NSString *destFolder)
{
    auto it = m_FileInfoMap.find(path.UTF8String);
    if (it != m_FileInfoMap.end())
    {
        if (zipExtract((void*)(&(it->second.m_PositionInZip)), destFolder.UTF8String, true)) {
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
    
}


#pragma mark - 从指定的 ZIP 文件位置提取文件到目标文件夹
BOOL YKZipManager::zipExtract(void *lpPositionInZip, const char *lpszDestFolder, BOOL bIsIgnorePathInZip)
{
    NSLog(@"[YKService]12");
    unzFile uf = m_Handle;
    
    NSLog(@"[YKService]13");
    unz64_file_pos *pPosition = (unz64_file_pos *)lpPositionInZip;
    unzGoToFilePos64(uf, pPosition);
    NSLog(@"[YKService]14");
    return zipExtractCurrentFile(lpszDestFolder, bIsIgnorePathInZip);
}

#pragma mark - 提取当前 ZIP 文件中的文件到目标文件夹
BOOL YKZipManager::zipExtractCurrentFile(const char *lpszDestFolder, BOOL bIsIgnorePathInZip)
{
    unzFile uf = m_Handle;
    
    char szFilePathA[MAX_PATH];
    unz_file_info64 FileInfo;
    
    // 获取当前文件的信息
    if (unzGetCurrentFileInfo64(uf, &FileInfo, szFilePathA, sizeof(szFilePathA), NULL, 0, NULL, 0) != UNZ_OK) {
        return NO; // 返回失败
    }
    
    // 打开当前文件
    if (unzOpenCurrentFile(uf) != UNZ_OK) {
        return NO; // 返回失败
    }
    

    // 构造目标路径
    std::string strDestPath = lpszDestFolder;
    if (!strDestPath.empty())
    {
        auto last_char = *strDestPath.rbegin();
        // 确保目标路径以斜杠结尾
        if (last_char != '\\' && last_char != '/') {
            strDestPath += '/'; // 添加分隔符
        }
    }
    

    // 获取当前文件名的长度
    size_t nLength = strlen(szFilePathA);
    char *lpszFileName = szFilePathA;
    
    // 如果忽略 ZIP 中的路径
    if (bIsIgnorePathInZip)
    {
        char* lpPureName = strrchr(lpszFileName, '/');
        if (lpPureName == NULL) {
            lpPureName = strrchr(lpszFileName, '\\');
        }
        
        if (lpPureName) {
            lpszFileName = lpPureName + 1; // 获取文件名
        }
    }
    
    const char* lpszCurrentFile = lpszFileName;
    
    // 构建目标路径
    for (int i = 0; i <= nLength; ++i)
    {
        if (lpszFileName[i] == ('\0')) {
            strDestPath += lpszCurrentFile; // 追加文件名
            //GBK 转换为 UTF8
            NSData *gbkData = [NSData dataWithBytes:strDestPath.c_str() length:strlen(strDestPath.c_str())];
            NSString *utf8String = [[NSString alloc] initWithData:gbkData encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
            if (utf8String) {
                strDestPath = [utf8String UTF8String];
            }
            break;
        }
        
        if (lpszFileName[i] == '\\' || lpszFileName[i] == '/') {
            auto FileNameDelimeter = lpszFileName[i];
            lpszFileName[i] = '\0';
            
            strDestPath += lpszCurrentFile; // 追加文件名
            strDestPath += FileNameDelimeter; // 添加分隔符
            //GBK 转换为 UTF8
            NSData *gbkData = [NSData dataWithBytes:strDestPath.c_str() length:strlen(strDestPath.c_str())];
            NSString *utf8String = [[NSString alloc] initWithData:gbkData encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
            if (utf8String) {
                strDestPath = [utf8String UTF8String];
            }
            createDirectoriesRecursively(strDestPath.c_str());//创建目录
            lpszCurrentFile = lpszFileName + i + 1; // 更新当前文件名
        }
    }
    
    if (lpszCurrentFile[0] == ('\0')) {
        unzCloseCurrentFile(uf); // 手动关闭当前文件
        return YES; // 返回成功
    }
    
    FILE *fp = fopen(strDestPath.c_str(), "wb"); // 打开目标文件
    if (fp == NULL) {
        unzCloseCurrentFile(uf); // 打开失败时关闭当前文件
        return NO; // 返回失败
    }
    
    const unsigned int BUFFER_SIZE = 4096;
    unsigned char byBuffer[BUFFER_SIZE];
    
    // 读取并写入文件
    while (YES)
    {
        int nSize = unzReadCurrentFile(uf, byBuffer, BUFFER_SIZE);
        
        if (nSize < 0) {
            fclose(fp); // 读取失败时关闭文件
            unzCloseCurrentFile(uf); // 关闭当前文件
            return NO; // 返回失败
        } else if (nSize == 0) {
            break; // 读取完成
        } else {
            size_t dwWritten = fwrite(byBuffer, 1, nSize, fp); // 写入数据
            if (dwWritten != nSize) {
                fclose(fp); // 写入失败时关闭文件
                unzCloseCurrentFile(uf); // 关闭当前文件
                return NO; // 返回失败
            }
        }
    }
    
    fclose(fp); // 成功时关闭目标文件
    unzCloseCurrentFile(uf); // 成功时关闭当前文件
    return YES; // 返回成功
}

#pragma mark - 文件名通配符匹配函数，支持 '*' 和 '?'。
int YKZipManager::fileNameWildCompare(const char *wild, const char *string)
{
    // 定义两个指针，用于记录匹配过程中的位置
    const char *cp = NULL, *mp = NULL;
    
    // 第一阶段：处理通配符前的匹配
    // 当字符没有匹配完成且当前模式不是 '*' 时进行匹配
    while ((*string) && (*wild != '*'))
    {
        // 若字符不相同且模式不是 '?'，则匹配失败
        if ((*wild != *string) && (*wild != '?'))
        {
            return 0;
        }
        // 若字符匹配成功或模式为 '?'，则继续匹配下一个字符
        wild++;
        string++;
    }
    
    // 第二阶段：处理包含 '*' 的模式匹配
    while (*string)
    {
        if (*wild == '*')
        {
            // 遇到 '*' 通配符，跳过 '*' 并记录此位置，用于回溯
            if (!*++wild)  // 若 '*' 是模式中的最后一个字符，直接返回成功
            {
                return 1;
            }
            mp = wild;       // 保存 '*' 后的模式位置
            cp = string + 1; // 保存当前字符串位置+1，以备失败后回溯
        }
        else if ((*wild == *string) || (*wild == '?'))
        {
            // 若字符匹配或模式为 '?'，继续匹配下一个字符
            wild++;
            string++;
        }
        else
        {
            // 回溯到上一个 '*' 位置，重新匹配
            wild = mp;
            string = cp++;
        }
    }
    
    // 第三阶段：跳过模式中多余的 '*' 确保模式已完全匹配
    while (*wild == '*')
    {
        wild++;
    }
    // 如果模式字符串已完全匹配完，返回 1，否则返回 0
    return !*wild;
}


#pragma mark - 创建递归文件夹
BOOL YKZipManager::createDirectoriesRecursively(const char *dir) {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 将 C 字符串转换为 NSString
    NSString *dirPath = [NSString stringWithUTF8String:dir];
    
    // 检查路径是否有效
    if (dirPath.length == 0) {
        return NO;
    }
    
    // 检查目录是否已存在
    if ([fileManager fileExistsAtPath:dirPath]) {
        return YES; // 如果目录已经存在，直接返回成功
    }
    
    // 分割路径
    NSArray *pathComponents = [dirPath pathComponents];
    NSMutableString *currentPath = [NSMutableString string];
    
    for (NSString *component in pathComponents) {
        // 忽略根路径
        if ([component isEqualToString:@"/"] || [component isEqualToString:@"."]) {
            continue;
        }
        
        // 更新当前路径
        [currentPath appendFormat:@"/%@", component];
        
        // 检查当前路径是否存在
        if (![fileManager fileExistsAtPath:currentPath]) {
            NSError *error = nil;
            // 创建目录
            BOOL success = [fileManager createDirectoryAtPath:currentPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
            if (!success) {
                return NO; // 目录创建失败
            }
            
            // 设置权限为 0777
            NSDictionary *attributes = @{
                NSFilePosixPermissions: @(0777) // 八进制表示
            };
            [fileManager setAttributes:attributes ofItemAtPath:currentPath error:&error];
            
            if (error) {
                return NO; // 设置权限失败
            }
        }
    }
    
    return YES; // 成功创建所有目录
}

