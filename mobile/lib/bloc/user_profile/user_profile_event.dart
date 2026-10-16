import 'package:equatable/equatable.dart';

abstract class UserProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileList extends UserProfileEvent {
  @override
  List<Object> get props => [];
}

class ProfileDetailsUpdateList extends UserProfileEvent {
  final int? id;
  final String firstname;
  final String lastname;
  final String email;
  final int? role;
  final String? address;
  final String? city;
  final String? password;
  final String? conPassword;
  final String? countryCode;
  final String? phone;
  final String? countryIsoCode;
  ProfileDetailsUpdateList(
      {this.id,
      this.password,
      this.conPassword,
      required this.firstname,
      required this.lastname,
      required this.email,
      this.city,
      this.phone,
      this.countryCode,
      this.countryIsoCode,
      this.address,
      this.role});
  @override
  List<Object?> get props => [
        id,
        firstname,
        lastname,
        role,
        address,
        email,
        city,
        countryCode,
        countryIsoCode,
        phone,
        password,
        conPassword
      ];
}

class ProfileListGet extends UserProfileEvent {
  ProfileListGet();

  @override
  List<Object> get props => [];
}
