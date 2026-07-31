import 'package:flutter/material.dart';

import 'package:rentease/services/auth_service.dart';



class RegisterScreen extends StatefulWidget {

  const RegisterScreen({super.key});


  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();

}



class _RegisterScreenState extends State<RegisterScreen> {


  final AuthService _authService = AuthService();


  final fullNameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();



  bool _obscurePassword = true;

  bool _obscureConfirmPassword = true;


  bool isLoading = false;



  Future<void> register() async {


    if(fullNameController.text.trim().isEmpty ||
       emailController.text.trim().isEmpty ||
       passwordController.text.trim().isEmpty){

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Please fill all fields"
          ),
        ),

      );

      return;

    }



    if(passwordController.text !=
       confirmPasswordController.text){


      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Password does not match"
          ),
        ),

      );


      return;

    }



    setState(() {

      isLoading = true;

    });



    try {


      final user =
      await _authService.register(

        fullName:
        fullNameController.text.trim(),


        email:
        emailController.text.trim(),


        password:
        passwordController.text.trim(),


        phone:
        "",


        role:
        "renter",

      );



      if(user != null){


        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(
            content: Text(
              "Account Created Successfully"
            ),
          ),

        );


        Navigator.pop(context);


      }



    }catch(e){


      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            e.toString()
          ),
        ),

      );


    }



    setState(() {

      isLoading = false;

    });


  }





  @override
  void dispose() {


    fullNameController.dispose();

    emailController.dispose();

    passwordController.dispose();

    confirmPasswordController.dispose();


    super.dispose();

  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor:
      const Color(0xFFF8F5FF),


      body: SafeArea(

        child: Padding(

          padding:
          const EdgeInsets.symmetric(
              horizontal: 24
          ),


          child: SingleChildScrollView(

            child: Column(

              children: [


                const SizedBox(height: 40),



                const Text(

                  "RentEase",

                  style: TextStyle(

                    fontSize: 32,

                    fontWeight:
                    FontWeight.bold,

                    color:
                    Color(0xFF6B46C1),

                  ),

                ),



                const SizedBox(height:40),



                const Text(

                  "Create Account",

                  style: TextStyle(

                    fontSize:28,

                    fontWeight:
                    FontWeight.bold,

                  ),

                ),



                const SizedBox(height:8),



                const Text(

                  "Join us to find your perfect rental",

                  style: TextStyle(

                    color:
                    Colors.black54,

                    fontSize:16,

                  ),

                ),



                const SizedBox(height:40),




                Container(


                  padding:
                  const EdgeInsets.all(24),


                  decoration:
                  BoxDecoration(

                    color:
                    Colors.white,


                    borderRadius:
                    BorderRadius.circular(24),



                    boxShadow:[

                      BoxShadow(

                        color:
                        Colors.black
                            .withOpacity(0.05),


                        blurRadius:20,


                        offset:
                        const Offset(0,10),

                      )

                    ],

                  ),




                  child: Column(

                    crossAxisAlignment:
                    CrossAxisAlignment.start,


                    children: [



                      const Text(
                        "Full Name",
                        style:_labelStyle,
                      ),


                      const SizedBox(height:8),



                      TextField(

                        controller:
                        fullNameController,


                        decoration:
                        _inputDecoration(
                            hint:"John Doe"
                        ),

                      ),




                      const SizedBox(height:20),




                      const Text(
                        "Email Address",
                        style:_labelStyle,
                      ),



                      const SizedBox(height:8),




                      TextField(

                        controller:
                        emailController,


                        keyboardType:
                        TextInputType.emailAddress,


                        decoration:
                        _inputDecoration(
                            hint:
                            "name@gmail.com"
                        ),

                      ),




                      const SizedBox(height:20),




                      const Text(
                        "Password",
                        style:_labelStyle,
                      ),




                      const SizedBox(height:8),




                      TextField(

                        controller:
                        passwordController,


                        obscureText:
                        _obscurePassword,


                        decoration:
                        _inputDecoration(

                          hint:"••••••••",

                          isPassword:true,


                          obscure:
                          _obscurePassword,


                          onVisibilityTap:(){

                            setState(() {

                              _obscurePassword =
                              !_obscurePassword;

                            });

                          },

                        ),

                      ),




                      const SizedBox(height:20),




                      const Text(
                        "Confirm Password",
                        style:_labelStyle,
                      ),




                      const SizedBox(height:8),




                      TextField(

                        controller:
                        confirmPasswordController,


                        obscureText:
                        _obscureConfirmPassword,


                        decoration:
                        _inputDecoration(

                          hint:"••••••••",


                          isPassword:true,


                          obscure:
                          _obscureConfirmPassword,


                          onVisibilityTap:(){


                            setState(() {


                              _obscureConfirmPassword =
                              !_obscureConfirmPassword;


                            });


                          },


                        ),

                      ),




                      const SizedBox(height:32),





                      SizedBox(


                        width:
                        double.infinity,


                        height:56,



                        child:
                        ElevatedButton(


                          onPressed:
                          isLoading
                              ? null
                              : register,



                          style:
                          ElevatedButton.styleFrom(


                            backgroundColor:
                            const Color(0xFF6B46C1),


                            shape:
                            RoundedRectangleBorder(

                              borderRadius:
                              BorderRadius.circular(30),

                            ),

                          ),



                          child:
                          isLoading

                              ?

                          const CircularProgressIndicator(
                            color:Colors.white,
                          )


                              :

                          const Text(

                            "Create Account",


                            style:
                            TextStyle(

                              color:
                              Colors.white,


                              fontSize:18,


                              fontWeight:
                              FontWeight.w600,

                            ),

                          ),


                        ),

                      ),




                      const SizedBox(height:24),




                      Row(

                        mainAxisAlignment:
                        MainAxisAlignment.center,


                        children:[


                          const Text(
                            "Already have account? ",
                            style:
                            TextStyle(
                              color:
                              Colors.black54,
                            ),
                          ),



                          GestureDetector(


                            onTap:(){

                              Navigator.pop(context);

                            },


                            child:
                            const Text(

                              "Sign in",

                              style:
                              TextStyle(

                                color:
                                Color(0xFF6B46C1),

                                fontWeight:
                                FontWeight.w600,

                              ),

                            ),

                          )


                        ],

                      )


                    ],

                  ),


                )

              ],

            ),

          ),

        ),

      ),

    );

  }

}





const TextStyle _labelStyle =
TextStyle(

  fontSize:14,

  fontWeight:
  FontWeight.w600,

  color:
  Colors.black87,

);





InputDecoration _inputDecoration({

  required String hint,

  bool isPassword=false,

  VoidCallback?
  onVisibilityTap,

  bool obscure=false,


}){


  return InputDecoration(


    hintText:
    hint,



    prefixIcon:
    Icon(

      isPassword
          ?
      Icons.lock_outline
          :
      Icons.person_outline,


      color:
      Colors.grey,

    ),



    suffixIcon:
    isPassword

        ?

    IconButton(

      icon:
      Icon(

        obscure

            ?

        Icons.visibility_off

            :

        Icons.visibility,

        color:
        Colors.grey,

      ),


      onPressed:
      onVisibilityTap,


    )


        :

    null,



    filled:true,


    fillColor:
    const Color(0xFFF8F5FF),



    border:
    OutlineInputBorder(

      borderRadius:
      BorderRadius.circular(12),

      borderSide:
      BorderSide.none,

    ),

  );

}