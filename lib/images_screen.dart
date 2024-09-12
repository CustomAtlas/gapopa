import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gapopa/bloc.dart';
import 'package:gapopa/dio_client.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ImagesBloc(DioClient()),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  SearchTextFieldWidget(),
                  ImagesGridViewWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SearchTextFieldWidget extends StatefulWidget {
  const SearchTextFieldWidget({
    super.key,
  });

  @override
  State<SearchTextFieldWidget> createState() => _SearchTextFieldWidgetState();
}

class _SearchTextFieldWidgetState extends State<SearchTextFieldWidget> {
  /// Here [searchController] for search textfield
  /// [searchTimer] for [debounce] metohod
  /// [query] field to not search if last query text are the same with this
  final searchController = TextEditingController();
  Timer? searchTimer;
  String query = '';

  /// Adding [debounce] listener to [searchController] to listen search textfield changes
  @override
  void initState() {
    searchController.addListener(() => debounce());
    super.initState();
  }

  /// Wait some time before we search images by our query
  void debounce() {
    if (query == searchController.text) {
      return;
    }
    final bloc = context.read<ImagesBloc>();
    bloc.query = searchController.text;
    searchTimer?.cancel();
    searchTimer = Timer(const Duration(milliseconds: 900), () {
      // Clear images list and set page to 1 if we have a new query
      bloc.images.clear();
      bloc.page = 1;
      query = searchController.text;
      context.read<ImagesBloc>().add(GetImagesEvent());
    });
  }

  /// Removing [debounce] listener from [searchController]
  /// and disposing it to free app resources
  @override
  void dispose() {
    searchController.removeListener(() => debounce());
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Get screen width for horizontal padding [lR] - left-right
    final commonCount = (MediaQuery.sizeOf(context).width / 150).toInt();
    final lR = commonCount > 6 ? 100.0 : 20.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(lR, 20, lR, 0),
      child: TextField(
        controller: searchController,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        decoration: const InputDecoration(
          hintText: 'Enter search',
          contentPadding: EdgeInsets.only(left: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(24),
            ),
          ),
        ),
      ),
    );
  }
}

class ImagesGridViewWidget extends StatefulWidget {
  const ImagesGridViewWidget({super.key});

  @override
  State<ImagesGridViewWidget> createState() => _ImagesGridViewWidgetState();
}

class _ImagesGridViewWidgetState extends State<ImagesGridViewWidget> {
  /// Get images list at first open app
  @override
  void initState() {
    context.read<ImagesBloc>().add(GetImagesEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /// Calculate GridView [crossAxisCount] depends on screen width
    final commonCount = (MediaQuery.sizeOf(context).width / 150).toInt();
    final count = commonCount < 1
        ? 1
        : commonCount > 6
            ? 6
            : commonCount;
    return BlocBuilder<ImagesBloc, ImagesState>(
      builder: (context, state) {
        final bloc = context.watch<ImagesBloc>();

        /// Show error text if [state] is [ImagesError]
        return state is ImagesError
            ? Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(state.error.toString()),
              )
            : Expanded(
                child: GridView.builder(
                    shrinkWrap: true,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: commonCount > 6 ? 100 : 20,
                      vertical: 20,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                    ),
                    itemCount: bloc.images.length,
                    itemBuilder: (_, i) {
                      bloc.index = i;
                      // Made pagination by [bloc.add(GetImagesEvent())] here
                      bloc.add(GetImagesEvent());
                      final e = bloc.images[i];
                      return ImageWidget(
                        imageUrl: e.previewURL,
                        likes: e.likes,
                        views: e.views,
                      );
                    }),
              );
      },
    );
  }
}

/// Widget with image, likes and views
class ImageWidget extends StatelessWidget {
  final String imageUrl;
  final int likes;
  final int views;
  const ImageWidget({
    super.key,
    required this.imageUrl,
    required this.likes,
    required this.views,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FullScreenImageWidget(imageUrl),
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            color: Color.fromARGB(255, 243, 241, 241),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 217, 215, 215),
                blurRadius: 5,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Hero(
                  tag: imageUrl,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    alignment: Alignment.topCenter,
                    fit: BoxFit.fitWidth,
                    height: 100,
                    errorWidget: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: FittedBox(
                        child: Text('Failed to load an image'),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              FittedBox(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Text('$likes likes'),
                      const SizedBox(width: 10),
                      Text('$views views'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenImageWidget extends StatelessWidget {
  const FullScreenImageWidget(this.imageUrl, {super.key});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: Hero(
              tag: imageUrl,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: double.infinity,
                width: double.infinity,
                errorWidget: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: FittedBox(
                    child: Text('Failed to load an image'),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: MaterialButton(
                padding: const EdgeInsets.all(15),
                elevation: 0,
                color: Colors.black12,
                highlightElevation: 0,
                minWidth: double.minPositive,
                height: double.minPositive,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
