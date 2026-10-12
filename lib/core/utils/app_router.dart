import 'package:etrip/features/Itinerary/presentation/views/itinerary_result_view.dart';
import 'package:etrip/features/Itinerary/presentation/views/itinerary_step_one.dart';
import 'package:etrip/features/Profile/presentation/views/widgets/about_me.dart';
import 'package:etrip/features/Profile/presentation/views/widgets/edit_profile.dart';
import 'package:etrip/features/auth/data/models/egyptopia_user.dart';
import 'package:etrip/features/home/presentation/views/home_view.dart';
import 'package:etrip/features/map/map_screen.dart';
import 'package:etrip/features/places/data/models/place_model.dart';
import 'package:etrip/features/weather/presentation/weather_screen.dart';
import 'package:etrip/features/wishlist/presentation/views/wish_list_view.dart';
import 'package:etrip/features/Profile/presentation/views/widgets/create_new_password.dart';
import 'package:etrip/features/chat_bot/chat_details.dart';
import 'package:etrip/features/auth/presentation/views/widgets/forget_password.dart';
import 'package:etrip/features/auth/presentation/views/registration_view.dart';
import 'package:etrip/features/auth/presentation/views/sign_in_view.dart';
import 'package:etrip/features/auth/presentation/views/sign_up_view.dart';
import 'package:etrip/features/places/presentation/place_details.dart';
import 'package:etrip/features/places/presentation/places_screen.dart';
import 'package:etrip/features/onbording/presentation/views/on_bording_view.dart';
import 'package:etrip/features/splash/presentation/views/splash_view.dart';
import 'package:etrip/screens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract class AppRouter {
  static const kOnBordingView = '/onBordingView';
  static const kRegistrationView = '/registrationView';
  static const kSignUp = '/signup';
  static const kSignIn = '/signin';
  static const kForgetPassword = '/forgetPassword';
  static const kCreateNewPassword = '/createNewPassword';
  static const kScreens = '/screens';
  static const kHomePage = '/home';
  static const kPlaces = '/places';
  static const kChatbot = '/chatbot';
  static const kPlaceDetails = '/placeDetails';
  static const kWeather = '/weather';
  static const kWishList = '/wishList';
  static const kEditProfile = '/editProfile';
  static const kAboutMe = '/aboutme';
  static const kItineraryStepone = '/itineraryStepone';
  static const kItineraryResult = '/itineraryResult';
  static const kMap = '/map';

  static final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashView()),
    GoRoute(
      path: kOnBordingView,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnBordingView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
        path: kRegistrationView,
        builder: (context, state) => const RegistrationView()),
    GoRoute(path: kSignUp, builder: (context, state) => const SignUpView()),
    GoRoute(path: kSignIn, builder: (context, state) => const SignInView()),
    GoRoute(
        path: kForgetPassword,
        builder: (context, state) => const ForgetPassword()),
    GoRoute(
        path: kCreateNewPassword,
        builder: (context, state) => const CreateNewPassword()),
    GoRoute(path: kScreens, builder: (context, state) => const Screens()),
    GoRoute(path: kHomePage, builder: (context, state) => const HomeView()),
    GoRoute(path: kPlaces, builder: (context, state) => const PlacesScreen()),
    GoRoute(path: kChatbot, builder: (context, state) => const ChatDetails()),
    GoRoute(path: kWishList, builder: (context, state) => const WishListView()),
    GoRoute(
      path: kPlaceDetails,
      builder: (context, state) {
        final place = state.extra as PlaceModel;
        return PlaceDetails(place: place);
      },
    ),
    GoRoute(path: kWeather, builder: (context, state) => WeatherScreen()),
    GoRoute(
        path: kEditProfile,
        builder: (context, state) {
          final user = state.extra as EgyptopiaUser;
          return EditProfile(
            user: user,
          );
        }),
    GoRoute(
        path: kAboutMe,
        builder: (context, state) {
          final user = state.extra as EgyptopiaUser;
          return AboutMe(
            user: user,
          );
        }),
      GoRoute(
      path: kItineraryStepone,
      builder: (context, state) => const ItineraryStepOne(),
    ),
    GoRoute(
  path: kItineraryResult,
  builder: (context, state) {
    final args = state.extra as Map<String, dynamic>;
    return ItineraryResultView(args: args);
  },
),
    GoRoute(path: kMap, builder: (context, state) {
      final place = state.extra as PlaceModel?;
      return MapScreen(initialFocusPlace: place);
    }),
  ]);
}
