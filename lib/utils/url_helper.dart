import '../constants.dart';
import '../services/preloaded_data_service.dart';

class UrlHelper {
  /// 修复相对路径 URL
  /// 支持协议相对路径（//example.com/...）和站内相对路径（/path/...）
  /// 如果已加载 CDN 配置，相对路径会优先使用 CDN 域名
  /// S3 URL 会自动替换为 S3 CDN URL（与 Discourse getURLWithCDN 一致）
  static String resolveUrl(String url) {
    if (url.startsWith('http')) {
      return url;
    }
    // 协议相对路径（//example.com/...）
    if (url.startsWith('//')) {
      final fullUrl = 'https:$url';
      // S3 CDN 重写：//linuxdo-uploads.s3.linux.do/... → https://cdn3.linux.do/...
      return _rewriteS3Cdn(fullUrl);
    }
    final base = PreloadedDataService().cdnUrl ?? AppConstants.baseUrl;
    if (url.startsWith('/')) {
      return '$base$url';
    }
    // 相对路径（如 letter_avatar_proxy/v4/...）
    return '$base/$url';
  }

  /// 将 S3 URL 替换为 S3 CDN URL
  /// 与 Discourse 前端 getURLWithCDN 中的 S3CDN 逻辑一致
  static String _rewriteS3Cdn(String url) {
    final preloaded = PreloadedDataService();
    final s3Cdn = preloaded.s3CdnUrl;
    final s3Base = preloaded.s3BaseUrl;
    if (s3Cdn == null || s3Base == null) return url;

    // s3BaseUrl 可能是 //linuxdo-uploads.s3.linux.do（协议相对），需要补 https:
    final s3BaseFull = s3Base.startsWith('//') ? 'https:$s3Base' : s3Base;
    if (url.startsWith(s3BaseFull)) {
      return url.replaceFirst(s3BaseFull, s3Cdn);
    }
    return url;
  }
}
