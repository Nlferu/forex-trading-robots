#include <Trade/Trade.mqh>

   CTrade trade;
   
   bool isPriceAbove = false;
   bool isPriceNearBuy = false;
   
   bool isPriceBelow = false;
   bool isPriceNearSell = false;

   input int MyTSSValue = 7;              // Tenkan Value
   input int MySSSValue = 28;             // Kijun Value
   input int MySSBValue = 119;            // SSB Value
   
   input double EqPercentSL = 0.10;       // Equity Percentage Sl
   input double EqPercentTP = 0.02;       // Equity Percentage Tp
   
   input double LocalHHLL = 60;          // HH and LL taken from x bars = 60
   
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
   
   string signal = "";
  
   // Close candle prices for M5
   
   MqlRates PriceInfoM5[];
   ArraySetAsSeries (PriceInfoM5, true);
   int DataM5 = CopyRates (Symbol(), PERIOD_M5, 0, (MySSBValue+3), PriceInfoM5);
   
   // Close candle prices for H4
   
   MqlRates PriceInfoH4[];
   ArraySetAsSeries (PriceInfoH4, true);
   int DataH4 = CopyRates (Symbol(), PERIOD_H4, 0, (MySSBValue+3), PriceInfoH4);
   
   //+------------------------------------------------------------------+
   //| TakeProfit, StopLoss                                             |
   //+------------------------------------------------------------------+
   
   double EquityStop = (1 - EqPercentSL)*Balance;
   double EquityProfit = (1 + EqPercentTP)*Balance;
   
   //+------------------------------------------------------------------+
   //| Ichimoku                                                         |
   //+------------------------------------------------------------------+
   
   // Ichi for M5
   
   int IchimokuDefinitionM5 = iIchimoku(_Symbol, PERIOD_M5, MyTSSValue, MySSSValue, MySSBValue); 
   
   double KijunArrayM5[];
   ArraySetAsSeries(KijunArrayM5, true);
   CopyBuffer(IchimokuDefinitionM5, 1, 0, (MySSSValue+3), KijunArrayM5);
   double KijunValue0M5 = KijunArrayM5[1];
   double KijunValueM5 = KijunArrayM5[MySSSValue];
   double KijunValueM5c = KijunArrayM5[MySSSValue+1];
   
   double SSBArrayM5[];
   ArraySetAsSeries(SSBArrayM5, true);
   CopyBuffer(IchimokuDefinitionM5, 3, 0, (MySSSValue+3), SSBArrayM5);
   double SSBValueM5 = SSBArrayM5[0]; 
   
   double ChikouArrayM5[];
   ArraySetAsSeries(ChikouArrayM5, true);
   CopyBuffer(IchimokuDefinitionM5, 4, 0, (MySSSValue+3), ChikouArrayM5);
   double ChikouValueM5 = ChikouArrayM5[MySSSValue+1];
   double ChikouValueM5c = ChikouArrayM5[(MySSSValue+2)];
   
   // Ichi for H4
   
   int IchimokuDefinitionH4 = iIchimoku(_Symbol, PERIOD_H4, MyTSSValue, MySSSValue, MySSBValue); 
   
   double KijunArrayH4[];
   ArraySetAsSeries(KijunArrayH4, true);
   CopyBuffer(IchimokuDefinitionH4, 1, 0, (MySSSValue+3), KijunArrayH4);
   double KijunValueH4 = KijunArrayH4[1];
   
   double SSBArrayH4[];
   ArraySetAsSeries(SSBArrayH4, true);
   CopyBuffer(IchimokuDefinitionH4, 3, 0, (MySSSValue+3), SSBArrayH4);
   double SSBValueH4 = SSBArrayH4[1];
   double SSBValueH4c = SSBArrayH4[2];
   
   //+------------------------------------------------------------------+
   //| Buy                                                              |
   //+------------------------------------------------------------------+
   
   if(!isPriceAbove)
      if(PriceInfoH4[1].close > SSBValueH4)
      {
         isPriceAbove = true;
      }  
   
   if(isPriceAbove)
      if(PriceInfoH4[1].close < SSBValueH4)
        {
         isPriceAbove = false;
        }
         
   if(isPriceAbove)
      if(!isPriceNearBuy)
         if(Bid - SSBValueH4 < 77*_Point)
            {
               isPriceNearBuy = true;
            }
   
   if(isPriceAbove)
   if(isPriceNearBuy)
      if(ChikouValueM5c < KijunValueM5c)
         if(ChikouValueM5 > KijunValueM5)
            if(PriceInfoM5[1].close > KijunValue0M5)
            {                         
               isPriceAbove = false;
               isPriceNearBuy = false;
               signal = "buy";
            }            
            
   
   //+------------------------------------------------------------------+
   //| Sell                                                             |
   //+------------------------------------------------------------------+
   
   if(!isPriceBelow)
      if(PriceInfoH4[1].close < SSBValueH4)
         {
            isPriceBelow = true;
         }
   
   if(isPriceBelow)
      if(PriceInfoH4[1].close > SSBValueH4)
        {
         isPriceBelow = false;
        }
         
   if(isPriceBelow)
      if(!isPriceNearSell)
         if(SSBValueH4 - Bid < 77*_Point)
            {
               isPriceNearSell = true;
            }
   
   if(isPriceBelow)
   if(isPriceNearSell)
      if(ChikouValueM5c > KijunValueM5c)
         if(ChikouValueM5 < KijunValueM5)
            if(PriceInfoM5[1].close < KijunValue0M5)
            {
               isPriceBelow = false;
               isPriceNearSell = false;
               signal = "sell";
            }                       
   //+------------------------------------------------------------------+
   //| Trades                                                           |
   //+------------------------------------------------------------------+  
   
     if(signal == "buy" && PositionsTotal() < 1)
     {
        trade.Buy(LotSize, _Symbol, Ask, NULL, NULL, NULL);
     }             
     
     if(signal == "sell" && PositionsTotal() < 1)
     {
        trade.Sell(LotSize, _Symbol, Bid, NULL, NULL, NULL);       
     } 
     
     BuyMoneyManagement(Equity, EquityStop, EquityProfit);
     SellMoneyManagement(Equity, EquityStop, EquityProfit);
     
     Comment("\nisPriceAbove: ", isPriceAbove,
             "\nisPriceNearBuy: ", isPriceNearBuy,
             "\nEquity: ", Equity,
             "\nsignal: ", signal);  
  }

   //+------------------------------------------------------------------+
   //| Money Management Handlers                                        |
   //+------------------------------------------------------------------+
  
 void BuyMoneyManagement(double Equity, double EquityStop, double EquityProfit)
   {    
      
     for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        int ticket = PositionGetTicket(i);
        int PositionDirection = PositionGetInteger(POSITION_TYPE);
        double PositionBuyPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        if(PositionDirection == POSITION_TYPE_BUY)
        {                 
        if(Equity <= EquityStop)
          {
           isPriceAbove = false;
           isPriceNearBuy = false;
           trade.PositionClose(ticket);
          }           
        
        if(Equity >= EquityProfit)
          {
           isPriceAbove = false;
           isPriceNearBuy = false;
           trade.PositionClose(ticket);
          }
        }     
      }   
   }
   
   void SellMoneyManagement(double Equity, double EquityStop, double EquityProfit)
   {    
      
     for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        int ticket = PositionGetTicket(i);
        int PositionDirection = PositionGetInteger(POSITION_TYPE);
        double PositionSellPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        if(PositionDirection == POSITION_TYPE_SELL)
        {                 
        if(Equity <= EquityStop)
          {
           isPriceBelow = false;
           isPriceNearSell = false;
           trade.PositionClose(ticket);
          }           
        
        if(Equity >= EquityProfit)
          {
           isPriceBelow = false;
           isPriceNearSell = false;
           trade.PositionClose(ticket);
          }
        }      
      }   
   }    