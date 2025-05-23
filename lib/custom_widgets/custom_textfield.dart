import 'package:flutter/material.dart';

class CustomtextField extends StatelessWidget {
  const CustomtextField({
    super.key,
    required this.hint,
    required this.label,
    this.prefix,
    this.postfix,
    this.keyboardtype,
    required this.obscure,
    this.obscureChracter,
    required this.customcontroller,
   // required this.validator,
    this.maxlines,
  });

  final String hint;
  final Widget label;
  final Widget? prefix;
  final Widget? postfix;
  final TextEditingController customcontroller;
  final TextInputType? keyboardtype;
  final bool obscure;
  final String? obscureChracter;
  //final FormFieldValidator<String> validator;
  final maxlines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: customcontroller,
        validator:  (value) {
          if (value == null || value.isEmpty) {
            return 'This field cannot be empty';
          }
          return null;
        },
        keyboardType: keyboardtype,
        obscureText: obscure,
        obscuringCharacter: obscure ? (obscureChracter ?? '*') : '*',
        maxLines: maxlines,
        cursorColor: Color(0XFF8a2be1),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          label: label,

          labelStyle: const TextStyle(color: Color(0xFF8a2be1)),
          prefixIcon: prefix,
          prefixIconColor: Color(0xFF0944c8),
          suffixIconColor: Color(0xFF0944c8),
          suffixIcon: postfix,
          
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
           
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF0944c8)),
            

          ),

        ),
      ),
    );
  }
}

