import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gapopa/dio_client.dart';
import 'package:gapopa/model.dart';

class ImagesBloc extends Bloc<ImagesEvent, ImagesState> {
  final DioClient _dioClient;
  ImagesBloc(this._dioClient) : super(ImagesInitial()) {
    on<ImagesEvent>((event, emit) async {
      switch (event) {
        case GetImagesEvent():
          await _getImagesEvent(event, emit);
      }
    });
  }

  /// Fields for fetching data from [_dioClient]
  final List<Model> images = [];
  int page = 1;
  int index = 0;
  bool isLoading = false;
  String query = '';

  /// Fetch data event from [_dioClient] with pagination and query
  ///
  /// 'if' block here to prevent multiple events at the same time
  Future<void> _getImagesEvent(
    GetImagesEvent event,
    Emitter<ImagesState> emit,
  ) async {
    if (index < images.length - 4 || isLoading) return;
    isLoading = true;
    emit(ImagesUpdating());
    try {
      final imagesResponse = await _dioClient.getImages(page, query);
      images.addAll(imagesResponse);
      page++;
      isLoading = false;
      images.isEmpty
          ? emit(ImagesError('Images not found'))
          : emit(ImagesUpdated());
    } catch (e) {
      emit(ImagesError(e));
    }
  }
}

/// Further [ImagesEvent] and [ImagesState] classes for [ImagesBloc]
sealed class ImagesEvent extends Equatable {}

class GetImagesEvent extends ImagesEvent {
  @override
  List<Object?> get props => [];
}

sealed class ImagesState extends Equatable {}

class ImagesInitial extends ImagesState {
  @override
  List<Object?> get props => [];
}

class ImagesUpdating extends ImagesState {
  @override
  List<Object?> get props => [];
}

class ImagesUpdated extends ImagesState {
  @override
  List<Object?> get props => [];
}

class ImagesError extends ImagesState {
  final Object error;

  ImagesError(this.error);

  @override
  List<Object?> get props => [error];
}
