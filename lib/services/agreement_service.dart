import '../dto/agreement_info.dart';
import 'http_service.dart';

class AgreementService {
  /// 获取协议内容
  Future<AgreementInfo> getAgreementInfo({
    required String type,
  }) async {
    final res = await HttpService.postForm<AgreementInfo>(
      '/apis/getFiles',
      {
        'type': type,
        'token': '',
        'userid': '',
      },
      fromData: (json) => AgreementInfo.fromJson(json),
    );
    return res.data!;
  }
}
