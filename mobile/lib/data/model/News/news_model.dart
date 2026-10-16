class NewsModel {
  final int? id;
  final String? dateCreated;
  final String? title;
  final int? likes;
  final String? image;
  final String? content;

  NewsModel({
    this.id,
    this.dateCreated,
    this.title,
    this.likes,
    this.image,
    this.content,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    // Handle image field - it can be a String, List, or null
    String? imageValue;
    if (json['image'] != null) {
      if (json['image'] is String) {
        imageValue = json['image'];
      } else if (json['image'] is List && (json['image'] as List).isNotEmpty) {
        // If it's a list, take the first item
        var firstItem = (json['image'] as List).first;
        if (firstItem is String) {
          imageValue = firstItem;
        } else if (firstItem is Map) {
          // Check for directus_files_id first (many-to-many relation)
          if (firstItem['directus_files_id'] != null) {
            imageValue = firstItem['directus_files_id']?.toString();
          } else if (firstItem['id'] != null) {
            imageValue = firstItem['id']?.toString();
          }
        }
      } else if (json['image'] is Map) {
        // If it's an object, try directus_files_id first, then id
        if (json['image']['directus_files_id'] != null) {
          imageValue = json['image']['directus_files_id']?.toString();
        } else if (json['image']['id'] != null) {
          imageValue = json['image']['id']?.toString();
        }
      }
    }

    return NewsModel(
      id: json['id'],
      dateCreated: json['date_updated'] ?? json['date_created'],
      title: json['title'],
      likes: json['likes'] ?? 0,
      image: imageValue,
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_created': dateCreated,
      'title': title,
      'likes': likes,
      'image': image,
      'content': content,
    };
  }
}
