#include <Trade/Trade.mqh>
CTrade trade;

input double CurrencyCorrector = 100;  // Depends on how many digits currency have -> for 3 digits (JPY) it is 100 -> for 5 digits it is 10000 so -> """ (digits - 1) = amount of "0" after 1 """

input double FixedStop = 30;           // StopLoss is 30/1000 -> 3% sl +10 spread = 40
input double AtrScope = 250;           // ATR up to 100
input double AtrMultiplier = 1;     // ATR Multiplier for SL -> SL = 0.5*ATR
input double EqPercentTr = 0.03;       // Equity Percentage Trailing Sl
input double TrailSlVal = 3000;        // It is GAP between current price and SL

void OnTick()
{

   double Balance = AccountInfoDouble(ACCOUNT_BALANCE); 
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   
   datetime time = TimeLocal();
   
   string hoursAndMinutes = TimeToString(time,TIME_MINUTES);   

  //+------------------------------------------------------------------+
  //| ATR                                                              |
  //+------------------------------------------------------------------+
   
   double ATRValue[];                   
   int ATRHandle = iATR(_Symbol, _Period, AtrScope); 
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
 
   double x = FixedStop/(Interval*10);
   double LotSize = NormalizeDouble(x, 2);
     
   double sl = (Interval + 1)*10;
   double tp = (Interval + 2)*10;  
      
   double stopS = Bid + ((Interval + sl)*_Point);    
   double stopB = Bid - ((Interval + sl)*_Point);
     
   double AutoTrail = (1 + EqPercentTr)*Balance; 
   
   if ((PositionsTotal()==0)&&(StringSubstr(hoursAndMinutes,0,5)=="08:00"))
   {
      trade.Buy(LotSize, _Symbol, Ask, stopB, NULL, NULL);
   }        

   CheckBuyTrailingSl(Ask, Equity, AutoTrail, ATR);   
   
//   if ((PositionsTotal()==0)&&(StringSubstr(hoursAndMinutes,0,5)=="08:00"))
//   {
//      trade.Sell(LotSize, _Symbol, Bid, stopS, NULL, NULL);
//   }        
//
//   CheckSellTrailingSl(Bid, Equity, AutoTrail, ATR);

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
         int PositionDirection = PositionGetInteger(POSITION_TYPE);
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