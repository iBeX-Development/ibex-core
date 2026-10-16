import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../data/repositories/News/news_repo.dart';
import 'news_event.dart';
import 'news_state.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  int _offset = 0;
  final int _limit = 10;
  bool _hasReachedMax = false;

  NewsBloc() : super(NewsInitial()) {
    on<FetchNewsList>(_onFetchNewsList);
    on<LoadMoreNews>(_onLoadMoreNews);
  }

  Future<void> _onFetchNewsList(
      FetchNewsList event, Emitter<NewsState> emit) async {
    try {
      emit(NewsLoading());
      _offset = 0;
      _hasReachedMax = false;

      final result = await NewsRepo().getNews(
        limit: _limit,
        offset: _offset,
      );

      if (result.isEmpty) {
        _hasReachedMax = true;
      } else {
        _offset += _limit;
      }

      emit(NewsSuccess(
        news: result,
        hasReachedMax: _hasReachedMax,
      ));
    } catch (e) {
      logger.e("Error fetching news: $e");
      emit(NewsError(message: e.toString()));
    }
  }

  Future<void> _onLoadMoreNews(
      LoadMoreNews event, Emitter<NewsState> emit) async {
    if (_hasReachedMax) return;

    if (state is NewsSuccess) {
      final currentState = state as NewsSuccess;

      try {
        final result = await NewsRepo().getNews(
          limit: _limit,
          offset: _offset,
        );

        if (result.isEmpty) {
          _hasReachedMax = true;
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          _offset += _limit;
          emit(NewsSuccess(
            news: [...currentState.news, ...result],
            hasReachedMax: false,
          ));
        }
      } catch (e) {
        logger.e("Error loading more news: $e");
        emit(NewsError(message: e.toString()));
      }
    }
  }
}
