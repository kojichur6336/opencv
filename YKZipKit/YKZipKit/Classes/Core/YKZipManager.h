//
//  YKZipMananger.h
//  YKZip
//
//  Created by xiaobin liu on 2024/10/30.
//

#pragma once
#include <map>
#include <string>
#include <vector>
#import <Foundation/Foundation.h>


/// @struct YKZIPCaseInsensitiveCompare
/// 用于文件名的无视大小写比较器，适合在 ZIP 文件名排序中使用。
struct YKZIPCaseInsensitiveCompare {
    /// @brief 重载的比较运算符，使用无视大小写的字符串比较。
    /// @param left 左侧待比较的字符串。
    /// @param right 右侧待比较的字符串。
    /// @return 如果左侧字符串小于右侧字符串（无视大小写），则返回 true；否则返回 false。
    bool operator()(const std::string& left, const std::string& right) const {
        return strcasecmp(left.c_str(), right.c_str()) < 0;
    }
};

/// @struct PositionInZip
/// 表示 ZIP 文件中的位置。`Data` 数组的第一个元素通常表示偏移量。
typedef struct
{
    unsigned long long Data[2]; ///< Data[0] 表示 ZIP 文件偏移量，Data[1] 用于存储附加信息。
} PositionInZip;

/// @struct FileInfoBlock
/// 存储 ZIP 文件中每个文件的详细信息。
struct FileInfoBlock
{
    std::string m_szFileName;       ///< 文件名，包含在 ZIP 压缩包中的文件的完整名称。
    std::string m_szRelativePath;   ///< 文件相对路径，指定文件在 ZIP 包中的路径。
    PositionInZip m_PositionInZip;  ///< 文件在 ZIP 中的偏移位置，用于快速定位文件。
};

typedef std::map<std::string, FileInfoBlock, YKZIPCaseInsensitiveCompare> FileInfoMap;



/// MARK - Zip管理类
class YKZipManager
{
public:
    
    /// 构造函数
    YKZipManager() { m_Handle = NULL; }
    
    /// 析构函数
    ~YKZipManager() { m_Handle = NULL; }
    
    
    /// 打开指定的 ZIP 文件
    /// - Parameters:
    ///   - zipFilePathName: ZIP 文件的路径
    ///   - prefixPath: 文件路径前缀，用于筛选 ZIP 文件中的文件。
    ///   - return:  如果成功打开 ZIP 文件，则返回 `YES`；否则返回 `NO`
    BOOL open(const char* lpszZipFilePathName, const char* lpszPrefixPath, const char *passwd = NULL);
    
    
    
    /// 关闭当前打开的 ZIP 文件
    /// - return 如果成功关闭 ZIP 文件，则返回 `YES`；否则返回 `NO`
    BOOL close();
    
    
    // 从压缩文件中提取指定的文件到目标文件夹。
    // 参数：
    // - lpszExtractFileName: 要提取的文件名。
    // - lpszDestFolder: 目标文件夹路径。
    // - bIsIgnorePathInZip: 是否忽略 ZIP 文件中的路径结构，提取到目标文件夹时是否保留原有目录结构
    // 返回值：如果操作成功，则返回 TRUE；否则返回 FALSE。
    BOOL extract(const char* lpszExtractFileName, const char* lpszDestFolder, BOOL bIsIgnorePathInZip = YES);
    
    

    // 从压缩文件中提取指定的文件到内存中的字节数组。
    // 参数：
    // - lpszExtractFileName: 要提取的文件名。
    // - rData: 存储提取数据的字节数组。
    // 返回值：如果操作成功，则返回 TRUE；否则返回 FALSE。
    BOOL extract(const char* lpszExtractFileName, std::vector<unsigned char> &rData);
    
    
    /// 创建 ZIP 文件并将指定目录的内容压缩到 ZIP 文件中
    /// @param path 压缩后的目标 ZIP 文件路径
    /// @param directoryPath 待压缩的目录路径
    /// @param keepParentDirectory 是否保持父目录结构
    /// @param password 设置密码（可选）
    /// @return 返回压缩操作是否成功
    static BOOL createZipFileAtPath(NSString * path, NSString *directoryPath, bool keepParentDirectory, NSString *password);
    
    
    /// 解压Zip
    /// @param path 目标路径
    /// @param destination 解压后的路径
    /// @param password 密码
    static BOOL unzipFileAtPath(NSString *path, NSString *destination, NSString *password);
    
    
    
    /// 获取IPA里面对应的名称Payload/XXX.app/ 就是要动态获取到这个XXX名称
    NSString * getIPAName();
    
    
    /// 解压指定文件到指定目录
    /// - Parameters:
    ///   - path: 目标路径
    ///   - destFolder: 目标文件夹
    BOOL extractFileAtPathFromIPA(NSString *path, NSString *destFolder);
private:
    
    /// 获取 ZIP 文件中的文件列表，并存储在指定的映射表中
    /// - Parameters:
    ///   - rMap: 文件信息映射表，用于存储 ZIP 文件中的文件信息
    ///   - lpszPrefixPath: 前缀路径，添加在每个文件路径前
    ///   Returns: 成功返回 true，失败返回 false
    BOOL extractFileList(FileInfoMap& rMap, const char* lpszPrefixPath);
    
    
    
    /// 从指定的 ZIP 文件位置提取文件到目标文件夹
    /// - Parameters:
    ///   - lpPositionInZip: 指向 ZIP 文件中要提取的文件位置的指针
    ///   - lpszDestFolder: 提取目标文件夹的路径
    /// - Returns: 如果成功提取文件，返回 TRUE；否则返回 FALSE
    BOOL zipExtract(void* lpPositionInZip, const char* lpszDestFolder, BOOL bIsIgnorePathInZip);
    
    
    /// 提取当前 ZIP 文件中的文件到目标文件夹
    /// - Parameters:
    ///   - lpszDestFolder: 提取目标文件夹的路径
    ///   - bIsIgnorePathInZip: 是否忽略 ZIP 文件中的路径结构，提取到目标文件夹时是否保留原有目录结构
    /// - Returns: 如果成功提取文件，返回 TRUE；否则返回 FALSE
    BOOL zipExtractCurrentFile(const char* lpszDestFolder, BOOL bIsIgnorePathInZip);
    
    
    /// 文件名通配符匹配函数，支持 '*' 和 '?'。
    /// - Parameters:
    ///   - wild: 包含通配符的模式字符串
    ///   - string: 要匹配的文件名字符串
    ///   - Returns：如果匹配返回 1，否则返回 0
    int fileNameWildCompare(const char *wild, const char *string);
    
    

    /// 将文件压缩并添加到 ZIP 文件中
    /// - Parameters:
    ///   - zf: ZIP 文件句柄，由 zipOpen64 打开并传入
    ///   - lpszFileNameInZip: ZIP 文件内部的目标文件路径（压缩后的文件在 ZIP 文件中的路径）
    ///   - lpszFiles: 要压缩的源文件路径，指定实际文件的位置
    ///   - passwd: ZIP 文件密码，可用于保护压缩的内容。传入 NULL 表示无密码保护
    ///   - bUtf8: 文件名编码方式标识。若为 true，则使用 UTF-8 编码，否则使用 GBK 编码
    ///   - Returns: 返回 TRUE 表示文件成功添加到 ZIP 中，FALSE 表示操作失败
    static BOOL addFiles(void* zf, const char* lpszFileNameInZip, const char* lpszFiles, const char *passwd, bool bUtf8);
    

    /// 将单个文件压缩并添加到 ZIP 文件中
    /// - Parameters:
    ///   - zf: ZIP 文件句柄，由 zipOpen64 打开并传入
    ///   - lpszFileNameInZip: ZIP 文件内部的目标文件路径（文件在 ZIP 内部的存储路径）
    ///   - lpszFilePath: 源文件路径，指向实际需要压缩的文件
    ///   - passwd: 文件的密码，如果传入密码则文件会被加密；传入 NULL 表示无密码保护
    ///   - bUtf8: 文件名编码方式标识。若为 true，使用 UTF-8 编码文件名；若为 false，则使用 GBK 编码文件名
    ///   - Returns:TRUE 表示文件成功添加到 ZIP 文件中，返回 FALSE 表示操作失败
    static BOOL addFile(void* zf, const char* lpszFileNameInZip, const char* lpszFilePath, const char *passwd, bool bUtf8);
    
    
    /// 创建文件夹
    /// - Parameter dir: 文件
    static BOOL createDirectoriesRecursively(const char *dir);
    
    /// 存储 ZIP 文件中各个文件的信息映射表，使用 FileInfoMap 类型管理文件信息
    FileInfoMap m_FileInfoMap;
    
    /// 指向 ZIP 文件句柄的指针，用于操作打开的 ZIP 文件
    /// 具体实现可以是 unzFile 类型，但为了不暴露类型，使用 void* 来保存
    void* m_Handle;
};
