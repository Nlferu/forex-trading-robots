#property copyright "Copyright 2021, OneTrueTrader"
#property link "https://www.onetruetrader.com"
#property version "1.00"

#property strict
#define LICENSE_TIME (360*86400)           // If time of expiration below not define, tool will expire after X*86400 days where X = days
#define LICENSE_FREE D'2021.05.05 00:00'   // Define time of expiration

#define LICENSE_FULL "OneTrueTrader_MoneyManager"
input string InpLicence = "Enter Licence Key Here";

#include <LicenceCheck.mqh>
#include <Trade/Trade.mqh>
CTrade trade;


input double FixedStop = 30;                 // Put here MaxLoss you can afford deducted by 15%

input int Label_Size = 10;                   // Chose Font Size for your Lot Size Info Label
input color Label_Color = 0;                 // Chose Color for your Lot Size Info Label

int AtrScope = 250;                          // ATR up to 100
int AtrMultiplier = 1;                       // ATR Multiplier for SL -> SL = 0.5*ATR
double EqPercentTr = 0.03;                   // Equity Percentage Trailing Sl
double TrailSlVal = 3000;                    // It is GAP between current price and SL

int CurrencyCorrector = 100;                 // Depends on how many digits currency have -> for 3 digits (JPY) it is 100 -> for 5 digits it is 10000 so -> """ (digits - 1) = amount of "0" after 1 """

int OnInit()
  {

   if(!LicenceCheck(InpLicence))
   return(INIT_FAILED);

   if(LicenceCheck(InpLicence))
   {}
   return(INIT_SUCCEEDED);
   
  }

void OnTick()
{

   if(LicenceCheck(InpLicence)) 
   {
   
   double Balance = AccountInfoDouble(ACCOUNT_BALANCE); 
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);

   if(_Digits == 3)
   {
      CurrencyCorrector = 100;
   }
   
   if(_Digits == 5)
   {
      CurrencyCorrector = 10000;
   }

  //+------------------------------------------------------------------+
  //| ATR                                                              |
  //+------------------------------------------------------------------+
   
   double ATRValue[];                   
   int ATRHandle = iATR(_Symbol, _Period, AtrScope);
   ArraySetAsSeries( ATRValue, true );
   if(CopyBuffer(ATRHandle, 0, 0, 5, ATRValue) > 0)
   {}
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
   
   double x = FixedStop/((Interval+1.5)*10);
   double LotSize = NormalizeDouble(x, 2);
     
   double sl = (Interval + 1)*10;
   double tp = (Interval + 2)*10;  
      
   double stopS = Bid + ((Interval + sl)*_Point);    
   double stopB = Bid - ((Interval + sl)*_Point);
     
   double AutoTrail = (1 + EqPercentTr)*Balance; 
   
   if(PositionsTotal() > 0)
   for(int i = PositionsTotal() - 1; i>=0; i--)
   {   
      string symbol = PositionGetSymbol(i);
        
      if(symbol == _Symbol)
      {      
         ulong PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double PositionSL = PositionGetDouble(POSITION_SL);
         
         if (PositionDirection == POSITION_TYPE_BUY && PositionSL == 0)
         {
            trade.PositionModify(PositionTicket, stopB, NULL); // stopB
         }
      }           
   }
   
   if(PositionsTotal() > 0)
   for(int i = PositionsTotal() - 1; i>=0; i--)
   {   
      string symbol = PositionGetSymbol(i);
        
      if(symbol == _Symbol)
      {      
         ulong PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double PositionSL = PositionGetDouble(POSITION_SL);
         
         if (PositionDirection == POSITION_TYPE_SELL && PositionSL == 0)
         {
            trade.PositionModify(PositionTicket, stopS, NULL); // stopB
         }
      }           
   }       

   CheckSellTrailingSl(Bid, Equity, AutoTrail, ATR);

   //+------------------------------------------------------------------+
   //| Information Label Regarding LotSize To Use                       |
   //+------------------------------------------------------------------+

   ObjectCreate(0, "Label 1",OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, "Label 1",OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "Label 1",OBJPROP_FONTSIZE, Label_Size);
   ObjectSetInteger(0, "Label 1",OBJPROP_COLOR, Label_Color); 
   ObjectSetString(0, "Label 1",OBJPROP_TEXT, "Preferred Lot Size: " + DoubleToString(LotSize,2));
   ObjectSetInteger(0, "Label 1", OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, "Label 1", OBJPROP_YDISTANCE, 20);
   }
}

   //+------------------------------------------------------------------+
   //| Money Management Handlers                                        |
   //+------------------------------------------------------------------+
 
   void CheckBuyTrailingSl (double Ask, double Equity, double AutoTrail, double ATR)
   {           
      
      double SL = NormalizeDouble(Ask - 2*ATR, _Digits);
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if(symbol == _Symbol)
        {
         ulong PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
         if(PositionDirection == POSITION_TYPE_BUY)
         if(Equity >= AutoTrail)
         if(CurrentStopLoss < SL)
          {
           trade.PositionModify(PositionTicket, (CurrentStopLoss + 50*_Point), NULL);
          }   
        }  
      }   
   }    
   
   void CheckSellTrailingSl (double Bid, double Equity, double AutoTrail, double ATR)
   {
                
      double SL = NormalizeDouble(Bid + 2*ATR, _Digits); 
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if(_Symbol == symbol)
        {
         ulong PositionDirection = PositionGetInteger(POSITION_TYPE);
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