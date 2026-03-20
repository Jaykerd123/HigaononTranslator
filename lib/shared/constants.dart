import 'package:flutter/material.dart';

const textInputDecoration = InputDecoration(
  fillColor: Color(0xFFF5F5F5),
  filled: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
    borderSide: BorderSide(color: Colors.redAccent, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
    borderSide: BorderSide(color: Colors.red, width: 1),
  ),
  labelStyle: TextStyle(color: Colors.grey),
  floatingLabelStyle: TextStyle(color: Colors.redAccent),
);

