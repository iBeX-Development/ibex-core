import 'package:equatable/equatable.dart';
import '../../data/model/News/news_model.dart';

abstract class NewsState extends Equatable {
  const NewsState();

  @override
  List<Object?> get props => [];
}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {}

class NewsSuccess extends NewsState {
  final List<NewsModel> news;
  final bool hasReachedMax;

  const NewsSuccess({
    required this.news,
    required this.hasReachedMax,
  });

  NewsSuccess copyWith({
    List<NewsModel>? news,
    bool? hasReachedMax,
  }) {
    return NewsSuccess(
      news: news ?? this.news,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [news, hasReachedMax];
}

class NewsError extends NewsState {
  final String message;

  const NewsError({required this.message});

  @override
  List<Object?> get props => [message];
}
