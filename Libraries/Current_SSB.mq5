
   //+------------------------------------------------------------------------+
   //|   In order to include this to ExpertAdvisor ->                         |
   //|                                                                        |
   //|      #import "Current_SSB.ex5"                                         |
   //|      double SSB();                                                     |
   //|      #import                                                           |
   //|                                                                        |
   //|   Then -> include this in OnTick()                                     |
   //|                                                                        |
   //|   //+------------------------------------------------------------------|
   //|   //| SSB Value not shifted from external function                     |
   //|   //+------------------------------------------------------------------|
   //|                                                                        |
   //|      double CurrentSsbValue = SSB(); -> call it as: CurrentSsbValue    |
   //|                                                                        |
   //+------------------------------------------------------------------------+    

#property library

double SSB() export
{
   
   int MySsbValue = 66;
   
   int IchimokuDef = iIchimoku(_Symbol, _Period, MySsbValue, MySsbValue, MySsbValue);
   
   double SsbArray[];
   ArraySetAsSeries(SsbArray, true);
   CopyBuffer(IchimokuDef, 1, 0, (MySsbValue + 3), SsbArray);
   double SsbCurrent = SsbArray[0];                         
   
   return SsbCurrent;
}