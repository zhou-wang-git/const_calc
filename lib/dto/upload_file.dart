class UploadFile {
  final String url;

  UploadFile({required this.url});

  factory UploadFile.fromJson(Map<String, dynamic> json) {
    return UploadFile(
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }
}
