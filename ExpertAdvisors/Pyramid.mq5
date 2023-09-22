   #include <Trade/Trade.mqh>

   CTrade trade;
 
   bool isTsKsCrossD = false;
   
   bool isSellSignal = false;
   bool isBuySignal = false;  
     
   input int MyTSSValue = 7;              // Tenkan Value
   input int MySSSValue = 28;             // Kijun Value
   input int MySSBValue = 119;            // SSB Value
   
   input double EqPercentSL = 0.05;       // Equity Percentage Sl
   input double EqPercentTP = 0.05;       // Equity Percentage Tp
   
   input double KsRange = 20;             // KsRange for grid
   input double MyKsVal = 1000;           // Ks range for trade occurance
   
   double PositionSellPrice;              // Remember 1st sell price from void
   double PositionSellPrice2;             // Remember 2nd sell price from sell
   double PositionSellPrice3;             // Remember 3rd sell price from sell
   double PositionSellPrice4;             // Remember 4th sell price from sell
   
void OnTick()
  {

   //+------------------------------------------------------------------+
   //| Prices                                                           |
   //+------------------------------------------------------------------+
   
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);

   double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double LotSize = NormalizeDouble((Balance/10000), 2);
   
   string TsKsCross = isTsKsCrossD;
   string signal = "";
  
   MqlRates PriceInfo[];
   ArraySetAsSeries (PriceInfo, true);
   int Data = CopyRates (Symbol(), Period(), 0, (MySSBValue+3), PriceInfo);
   
   
   //+------------------------------------------------------------------+
   //| TakeProfit, StopLoss                                             |
   //+------------------------------------------------------------------+
   
   double EquityStop = (1 - EqPercentSL)*Balance;
   double EquityOpen2 = (1 + EqPercentTP)*Balance;
   double EquityOpen3 = (1 + EqPercentTP/0.320513)*Balance;
   double EquityOpen4 = (1 + EqPercentTP/0.15674)*Balance;
   double EquityOpenF = (1 + EqPercentTP/0.091408)*Balance; 
   
   //+------------------------------------------------------------------+
   //| Ichimoku                                                         |
   //+------------------------------------------------------------------+
   
   int IchimokuDefinition = iIchimoku(_Symbol, _Period, MyTSSValue, MySSSValue, MySSBValue);
   
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
                  
   if(isSellSignal)
      if(KijunValue - Bid < MyKsVal*_Point)      
         {
            isTsKsCrossD = false;
            isSellSignal = false;
            signal = "sell";
         }             
   
   if(Equity >= EquityOpen2)
   if(PositionsTotal() == 1)
      {     
         signal = "sell2";    
      }
      
   if(Equity >= EquityOpen3)
   if(PositionsTotal() == 2)
      {     
         signal = "sell3";    
      }   
      
   if(Equity >= EquityOpen4)
   if(PositionsTotal() == 3)  
       {     
          signal = "sell4";    
       }        
            
   //+------------------------------------------------------------------+
   //| Trades                                                           |
   //+------------------------------------------------------------------+
   
   if(signal == "sell" && PositionsTotal() < 1)
   {
      trade.Sell(LotSize, _Symbol, Bid, NULL, NULL, NULL);                   
   }      
   
   if(PositionsTotal() == 1)
   CheckPyramidStop(Equity, EquityStop, EquityOpen2);
   
   if(signal == "sell2" && PositionsTotal() < 3)
   {
      trade.Sell(LotSize, _Symbol, Bid, PositionSellPrice - 4*_Point, NULL, NULL);
      PositionSellPrice2 = PositionGetDouble(POSITION_PRICE_CURRENT);           
   }
   
   if(PositionsTotal() == 2)
   CheckPyramidStop2(Equity, EquityOpen3);
   
   if(signal == "sell3" && PositionsTotal() < 4) 
   {
      trade.Sell(LotSize, _Symbol, Bid, PositionSellPrice2 - 4*_Point, NULL, NULL);
      PositionSellPrice3 = PositionGetDouble(POSITION_PRICE_CURRENT);        
   }
   
   if(PositionsTotal() == 3)
   CheckPyramidStop3(Equity, EquityOpen4);
   
   if(signal == "sell4" && PositionsTotal() < 5) 
   {
      trade.Sell(LotSize, _Symbol, Bid, PositionSellPrice3 - 4*_Point, NULL, NULL);
      PositionSellPrice4 = PositionGetDouble(POSITION_PRICE_CURRENT);       
   }
   
   if(PositionsTotal() == 4)
   CheckPyramidStopF(Equity, EquityOpenF);
   
  //Comment("\nPositionSellPrice2: ", PositionSellPrice,
  //        "\nPositionSellPrice3: ", AutoSL,
  //        "\nPositionSellPrice4: ", EquityStop);           
   
  }

   //+------------------------------------------------------------------+
   //| Money Management Handlers                                        |
   //+------------------------------------------------------------------+

void CheckPyramidStop(double Equity, double EquityStop, double EquityOpen2)
   {   
                    
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        int ticket = PositionGetTicket(i);
        int PositionDirection = PositionGetInteger(POSITION_TYPE);
        PositionSellPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        if(PositionDirection == POSITION_TYPE_SELL)
                         
        if(Equity <= EquityStop)
          {
           trade.PositionClose(ticket);
          } 
          
        if(Equity >= EquityOpen2)
          {
           trade.PositionModify(ticket, PositionSellPrice - 4*_Point, NULL);
          }   
      }   
   }
   
void CheckPyramidStop2(double Equity, double EquityOpen3)
   {   
                    
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        int ticket = PositionGetTicket(i);
        int PositionDirection = PositionGetInteger(POSITION_TYPE);
        if(PositionDirection == POSITION_TYPE_SELL)
        
        if(Equity >= EquityOpen3)
          {
           trade.PositionModify(ticket, PositionSellPrice2 - 4*_Point, NULL);        
          }
      } 
   } 

void CheckPyramidStop3(double Equity, double EquityOpen4)
   {   
                    
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        int ticket = PositionGetTicket(i);
        int PositionDirection = PositionGetInteger(POSITION_TYPE);
        if(PositionDirection == POSITION_TYPE_SELL)
        
        if(Equity >= EquityOpen4)
          {
           trade.PositionModify(ticket, PositionSellPrice3 - 4*_Point, NULL);        
          }
      } 
   }

void CheckPyramidStopF(double Equity, double EquityOpenF)
   {   
                    
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        int ticket = PositionGetTicket(i);
        int PositionDirection = PositionGetInteger(POSITION_TYPE);
        if(PositionDirection == POSITION_TYPE_SELL)
        
        if(Equity >= EquityOpenF)
          {
           trade.PositionClose(ticket);        
          }
      } 
   }
  