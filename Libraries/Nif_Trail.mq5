#property library

   #include <Trade/Trade.mqh>

   CTrade trade;

   //*** Nif Trail ***\\

   bool isSellSignal = false;
   bool isTsKsCrossD = false;
   
   bool isBuySignal = false;
   bool isTsKsCrossU = false;
   
   bool isEANifTrail = true;  
     
   input int MyTSSValue = 7;              // Tenkan Value
   input int MySSSValue = 28;             // Kijun Value
   input int MySSBValue = 119;            // SSB Value
   
   input double EqPercentBE = 0.12;       // Equity Percentage Be
   
   input double KsRange = 20;             // KsRange for grid
   input double MyKsVal = 1000;           // Ks range for trade occurance
   
   input double FixedStop = 40;           // StopLoss is 30/1000 -> 3% sl +10 spread = 40
   input double CurrencyCorrector = 100;  // Depends on how many digits currency have -> for 3 digits (JPY) it is 100 -> for 5 digits it is 10000 so -> """ (digits - 1) = amount of "0" after 1 """
  
   input double AtrScope = 250;           // ATR up to 100
   input double AtrMultiplier = 0.18;     // ATR Multiplier for SL -> SL = 0.5*ATR
   input double EqPercentTr = 0.03;       // Equity Percentage Trailing Sl
   input double TrailSlVal = 3000;        // It is GAP between current price and SL

void NifTrail() export
  {
   
   //+------------------------------------------------------------------+
   //| Prices                                                           |
   //+------------------------------------------------------------------+
   
   double Bid = NormalizeDouble(SymbolInfoDouble("EURJPY", SYMBOL_BID), _Digits);
   double Ask = NormalizeDouble(SymbolInfoDouble("EURJPY", SYMBOL_ASK), _Digits);

   double Balance = 1000;
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   string TsKsCross = isTsKsCrossD;
   string signal = "";
  
   MqlRates PriceInfo[];
   ArraySetAsSeries (PriceInfo, true);
   int Data = CopyRates ("EURJPY", Period(), 0, (MySSBValue+3), PriceInfo);
   
  //+------------------------------------------------------------------+
  //| ATR                                                              |
  //+------------------------------------------------------------------+
   
   double ATRValue[];                   
   int ATRHandle = iATR("EURJPY", 0, AtrScope); 
   ArraySetAsSeries( ATRValue, true );
   if(CopyBuffer(ATRHandle, 0, 0, 5, ATRValue) > 0);

   double ATR = ATRValue[0];
   
   double Interval = AtrMultiplier*ATR*CurrencyCorrector;
   
   // ** Error Handler **
   
   if(Interval == 0)
   {
      Interval = 30;
   }
   
   //+------------------------------------------------------------------+
   //| TakeProfit, StopLoss                                             |
   //+------------------------------------------------------------------+
   
   double AutoBE = (1 + EqPercentBE)*Balance;
 
   double x = FixedStop/(Interval*10);
   double LotSize = NormalizeDouble(x, 2);
     
   double sl = (Interval + 1)*10;
   double tp = (Interval + 2)*10;  
      
   double stopS = Bid + ((Interval + sl)*_Point);
     
   double stopB = Bid - ((Interval + sl)*_Point);
     
   double AutoTrail = (1 + EqPercentTr)*Balance;   
   double TrailSellSL = stopS;                          
   double TrailBuySL = stopB;   
   
   //+------------------------------------------------------------------+
   //| Ichimoku                                                         |
   //+------------------------------------------------------------------+
   
   int IchimokuDefinition = iIchimoku("EURJPY", _Period, MyTSSValue, MySSSValue, MySSBValue);
   
   double TenkanArray[];
   ArraySetAsSeries(TenkanArray, true);
   CopyBuffer(IchimokuDefinition, 0, 0, (MySSSValue+3), TenkanArray);
   double TenkanValue = TenkanArray[0];
   double TenkanValues = TenkanArray[1];
   double TenkanValueS = TenkanArray[MySSSValue];
   double TenkanValueSs = TenkanArray[(MySSSValue+1)];   
   
   double KijunArray[];
   ArraySetAsSeries(KijunArray, true);
   CopyBuffer(IchimokuDefinition, 1, 0, (MySSSValue+3), KijunArray);
   double KijunValue = KijunArray[0];
   double KijunValues = KijunArray[1];
   double KijunValueS = KijunArray[MySSSValue];
   double KijunValueSs = KijunArray[(MySSSValue+1)];
   
   double SSAArray[];
   ArraySetAsSeries(SSAArray, true);
   CopyBuffer(IchimokuDefinition, 2, 0, (MySSSValue+3), SSAArray);
   double SSAValue = SSAArray[0];
   double SSAValueS = SSAArray[MySSSValue];
   double SSAValueSs = SSAArray[(MySSSValue+1)];
   
   double SSBArray[];
   ArraySetAsSeries(SSBArray, true);
   CopyBuffer(IchimokuDefinition, 3, 0, (MySSSValue+3), SSBArray);
   double SSBValue = SSBArray[0];
   double SSBValueS = SSBArray[MySSSValue];
   double SSBValueSs = SSBArray[(MySSSValue+1)];

   double ChikouArray[];
   ArraySetAsSeries(ChikouArray, true);
   CopyBuffer(IchimokuDefinition, 4, 0, (MySSSValue+3), ChikouArray);
   double ChikouValue = ChikouArray[MySSSValue];
   double ChikouValueS = ChikouArray[(MySSSValue+1)];
   
   
   //+------------------------------------------------------------------+
   //| Buy                                                              |
   //+------------------------------------------------------------------+
   
   if(!isTsKsCrossU)
      if(TenkanValues < KijunValues)
         if(TenkanValue >= KijunValue)   
            {
               isTsKsCrossU = true;
            }
            
   if(isTsKsCrossU)
      if(TenkanValues > KijunValues)
         if(TenkanValue < KijunValue && TenkanValueS < KijunValueS)   
            {
               isTsKsCrossU = false;
            }            
   
   if(isTsKsCrossU)
      if(!isBuySignal)   
         if(PriceInfo[1].close > SSBValue && PriceInfo[1].close > SSAValue && PriceInfo[1].close > KijunValue && PriceInfo[1].close > TenkanValue)
         if(ChikouValueS > SSBValueSs && ChikouValueS > SSAValueSs && ChikouValueS > KijunValueSs && ChikouValueS > TenkanValueSs && ChikouValueS > PriceInfo[(MySSSValue+1)].high)
             if(KijunValue > SSBValue && KijunValue > SSAValue)
               if(TenkanValue > SSBValue && TenkanValue > SSAValue)                        
                     {
                        isBuySignal = true;
                     }               
   
   //+------------------------------------------------------------------+
   //| Sell                                                             |
   //+------------------------------------------------------------------+
   
   if(!isTsKsCrossD)
      if(TenkanValues > KijunValues)
         if(TenkanValue <= KijunValue)   
            {
               isTsKsCrossD = true;
            }
            
   if(isTsKsCrossD)
      if(TenkanValues < KijunValues)
         if(TenkanValue > KijunValue && TenkanValueS > KijunValueS)   
            {
               isTsKsCrossD = false;
            }            
   
   if(isTsKsCrossD)
      if(!isSellSignal)   
         if(PriceInfo[1].close < SSBValue && PriceInfo[1].close < SSAValue && PriceInfo[1].close < KijunValue && PriceInfo[1].close < TenkanValue)
         if(ChikouValueS < SSBValueSs && ChikouValueS < SSAValueSs && ChikouValueS < KijunValueSs && ChikouValueS < TenkanValueSs && ChikouValueS < PriceInfo[(MySSSValue+1)].low)
             if(KijunValue < SSBValue && KijunValue < SSAValue)
               if(TenkanValue < SSBValue && TenkanValue < SSAValue)                        
                     {
                        isSellSignal = true;
                     }
                     
   //+-------------------------------------------------------------------------------------------------------+
   //| Change to 1 or 2 trades -> unComment Grid line 1 and 2 + add/delete marked line in if(isSellSignal)   |
   //+-------------------------------------------------------------------------------------------------------+
                  
   if(isSellSignal)
      if(KijunValue - Bid < MyKsVal*_Point) 
      if((KijunValue - Bid < KsRange*_Point) && Bid < KijunValue && Bid < SSBValue && Bid < SSAValue) // Condition for trades allowed only near KS    
         {
            isTsKsCrossD = false;
            isSellSignal = false;
            signal = "sell";
         }             
   
   if(isBuySignal)
      if(Ask - KijunValue < MyKsVal*_Point)
      if((Ask - KijunValue < KsRange*_Point) && Ask > KijunValue && Ask > SSBValue && Ask > SSAValue) // Condition for trades allowed only near KS    
         {
            isTsKsCrossU = false;
            isBuySignal = false;
            signal = "buy";
         }
            
   //+------------------------------------------------------------------+
   //| Trades                                                           |
   //+------------------------------------------------------------------+
  
   //                  *** Sell ***
   
   if(signal == "sell" && CountPositionsPerEA() < 1)
   {
      trade.Sell(LotSize, "EURJPY", Bid, TrailSellSL, NULL, NULL);  // dynamic lots swap      
   }        
   
   CheckSellTrailingSl(Bid, Equity, AutoTrail, ATR);
   
   
   //                  *** Buy ***
   
//   if(signal == "buy" && PositionsTotal() < 1)
//   {
//      trade.Sell(LotSize, "EURJPY", Bid, TrailSellSL, NULL, NULL);
//   }     
//     
//   CheckSellTrailingSl(Bid, Equity, AutoTrail, ATR);

   
   //Comment("\nTsKsCrossD is: ", TsKsCross);
                         
  }
  
   //+------------------------------------------------------------------+
   //| Money Management Handlers                                        |
   //+------------------------------------------------------------------+
 
 void CheckSellTrailingSl (double Bid, double Equity, double AutoTrail, double ATR)
   {
                
      double SL = NormalizeDouble(Bid + 2*ATR, _Digits); // 2 x ATR sl
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if("EURJPY" == symbol)
        {
         int PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
         if(PositionDirection == POSITION_TYPE_SELL)
         if(Equity >= AutoTrail)
         if(CurrentStopLoss > SL)
          {
           trade.PositionModify(PositionTicket, (CurrentStopLoss - 50*_Point), NULL); // O tyle sie przesuwa co tick
          }   
        }  
      }   
   }
   
   int CountPositionsPerEA()
   {
      int NumberOfOpenedPositionsPerEA = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            string CurrencyPair = PositionGetSymbol(i);
            if("EURJPY" == CurrencyPair && isEANifTrail)
               {
                  NumberOfOpenedPositionsPerEA = NumberOfOpenedPositionsPerEA + 1;
               }
         }
      
      return NumberOfOpenedPositionsPerEA;   
   }               