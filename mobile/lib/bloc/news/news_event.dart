import 'package:equatable/equatable.dart';

abstract class NewsEvent extends Equatable {
  const NewsEvent();

  @override
  List<Object?> get props => [];
}

class FetchNewsList extends NewsEvent {
  const FetchNewsList();
}

class LoadMoreNews extends NewsEvent {
  const LoadMoreNews();
}
