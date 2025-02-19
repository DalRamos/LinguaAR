import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lingua_arv1/repositories/Config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:lingua_arv1/bloc/Gif/gif_event.dart';
import 'package:lingua_arv1/bloc/Gif/gif_state.dart';

class GifBloc extends Bloc<GifEvent, GifState> {
  GifBloc() : super(GifInitial()) {
    on<FetchGif>(_onFetchGif);
  }

  Future<void> _onFetchGif(FetchGif event, Emitter<GifState> emit) async {
    emit(GifLoading());

    String url = "${Cloud_url.baseURL}?public_id=${event.publicId}";

    print("Fetching GIF for: ${event.phrase}");
    print("Generated URL: $url"); 

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print("Response received: $jsonResponse");

        emit(GifLoaded(gifUrl: jsonResponse['gif_url'], phrase: event.phrase));
      } else {
        print("Failed request. Status Code: ${response.statusCode}");
        emit(GifError(message: 'Failed to fetch GIF from server.'));
      }
    } catch (error) {
      print("Error occurred: $error");
      emit(GifError(message: 'Error occurred: $error'));
    }
  }
}
