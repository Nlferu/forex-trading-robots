
#property copyright "Copyright 2021, OneTrueTrader"
#property link "https://www.onetruetrader.com"
#property version "2.00"

#property strict

#property script_show_inputs

#include  <LicenceCheck.mqh>

input string InpPrivateKey = "";
input string InpAccount = "";

   void OnStart()
      {
         string key = KeyGen(InpAccount, InpPrivateKey);
         Alert("The Key is " + key);
         Print("The Key is " + key);
      }
