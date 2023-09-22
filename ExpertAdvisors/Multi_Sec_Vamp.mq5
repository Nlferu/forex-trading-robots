   //---------------------------------\\   
   
   // *** KijunCrossD1Trail *** \\ 2
   
   // - USDJPY - Sell   
   
   //---------------------------------\\
   
   // *** NifTrail *** \\ 3
   
   // - EURJPY - Sell
   
   //---------------------------------\\
   
   // *** TenkanBend *** \\ 4
   
   // - USDJPY - Buy == Sell
   // - EURJPY - Buy == Sell
   // - GBPJPY - Buy == Sell
   
   //---------------------------------\\   
   
   // *** KijunSSBH4 *** \\ 5
   
   // - USDJPY - Buy
   // - GBPJPY - Buy and Sell
   // - GBPUSD - Sell
   
   //---------------------------------\\   
   
   // *** Pips_Vampire *** \\ 6
   
   // - EURJPY - Sell
   // - GBPUSD - Sell
   // - EURUSD - Sell
   // - GBPJPY - Sell  
   
   //---------------------------------\\

   #import "D1_Trail.ex5"                                         
   void D1Trail();
   double AccountBalanceUSDJPY();                                                    
   #import

   #import "Nif_Trail.ex5"                                         
   void NifTrail();
   double AccountBalanceEURJPY();                                                    
   #import 
  
   #import "Ts_Bend.ex5"                                         
   void TsBendTr();
   double AccountBalanceUSDJPY_Ts_Bend();
   double AccountBalanceEURJPY_Ts_Bend();
   double AccountBalanceGBPJPY_Ts_Bend();                                                       
   #import 
   
   #import "Kijun_SSBH4.ex5"                                         
   void KijunSSBH4();
   double AccountBalanceUSDJPY_Ks_SSB();
   double AccountBalanceGBPJPY_Ks_SSB();
   double AccountBalanceGBPUSD_Ks_SSB();                                                    
   #import
   
   #import "Pips_Vamp.ex5"                                         
   void PipsVampire();
   double AccountBalanceEURJPY_Pips_Vamp();
   double AccountBalanceEURUSD_Pips_Vamp();
   double AccountBalanceGBPJPY_Pips_Vamp(); 
   double AccountBalanceGBPUSD_Pips_Vamp();                                                      
   #import     
   
void OnTick()
  {  

   D1Trail();   
   NifTrail();
   TsBendTr();   
   KijunSSBH4();
   PipsVampire();
   
   double AccountBalanceSumTsBend = AccountBalanceUSDJPY_Ts_Bend() + AccountBalanceEURJPY_Ts_Bend() + AccountBalanceGBPJPY_Ts_Bend();
   double AccountBalanceSumKsSSB = AccountBalanceUSDJPY_Ks_SSB() + AccountBalanceGBPJPY_Ks_SSB() + AccountBalanceGBPUSD_Ks_SSB();
   double AccountBalanceSumPipsVamp = AccountBalanceEURJPY_Pips_Vamp() + AccountBalanceEURUSD_Pips_Vamp() + AccountBalanceGBPJPY_Pips_Vamp() + AccountBalanceGBPUSD_Pips_Vamp();
   
   ObjectCreate(_Symbol, "Label 1",OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, "Label 1",OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "Label 1",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Label 1",OBJPROP_COLOR, clrDarkViolet); 
   ObjectSetString(0, "Label 1",OBJPROP_TEXT, "1000 - H4_Ks Account Balance: " + AccountBalanceUSDJPY());
   ObjectSetInteger(0, "Label 1", OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, "Label 1", OBJPROP_YDISTANCE, 15);
   
   ObjectCreate(_Symbol, "Label 2",OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, "Label 2",OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "Label 2",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Label 2",OBJPROP_COLOR, clrBlueViolet); 
   ObjectSetString(0, "Label 2",OBJPROP_TEXT, "1000 - Nif_Trail Account Balance: " + AccountBalanceEURJPY());
   ObjectSetInteger(0, "Label 2", OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, "Label 2", OBJPROP_YDISTANCE, 30);
   
   ObjectCreate(_Symbol, "Label 3",OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, "Label 3",OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "Label 3",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Label 3",OBJPROP_COLOR, clrDarkViolet); 
   ObjectSetString(0, "Label 3",OBJPROP_TEXT, "3000 - Ts_Bend Account Balance: " + AccountBalanceSumTsBend);
   ObjectSetInteger(0, "Label 3", OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, "Label 3", OBJPROP_YDISTANCE, 45);
   
   ObjectCreate(_Symbol, "Label 4",OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, "Label 4",OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "Label 4",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Label 4",OBJPROP_COLOR, clrBlueViolet); 
   ObjectSetString(0, "Label 4",OBJPROP_TEXT, "4000 - Ks_SSB Account Balance: " + AccountBalanceSumKsSSB);
   ObjectSetInteger(0, "Label 4", OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, "Label 4", OBJPROP_YDISTANCE, 60);
   
   ObjectCreate(_Symbol, "Label 5",OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, "Label 5",OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "Label 5",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Label 5",OBJPROP_COLOR, clrDarkViolet); 
   ObjectSetString(0, "Label 5",OBJPROP_TEXT, "4000 - Pips_Vamp Account Balance: " + AccountBalanceSumPipsVamp);
   ObjectSetInteger(0, "Label 5", OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, "Label 5", OBJPROP_YDISTANCE, 75);               
  
  }
    