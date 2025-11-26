//+------------------------------------------------------------------+
//| Indicators module                                                |
//+------------------------------------------------------------------+
#ifndef __BOTTRADER_INDICATORS_MQH__
#define __BOTTRADER_INDICATORS_MQH__

#include <_BotTrader/Parameters.mqh>

//+------------------------------------------------------------------+
//| Structures                                                       |
//+------------------------------------------------------------------+
struct SIndicatorData
  {
   double   donchianHighEntry;
   double   donchianLowEntry;
   double   donchianHighExit;
   double   donchianLowExit;
   double   atr;
   datetime lastCalculation;
  };

//+------------------------------------------------------------------+
//| Internal state                                                   |
//+------------------------------------------------------------------+
int g_atrHandle=-1;

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
double ArrayMaxValue(const double &values[],int count)
  {
   double max_value=values[0];
   for(int i=1;i<count;i++)
     {
      if(values[i]>max_value)
         max_value=values[i];
     }
   return(max_value);
  }

double ArrayMinValue(const double &values[],int count)
  {
   double min_value=values[0];
   for(int i=1;i<count;i++)
     {
      if(values[i]<min_value)
         min_value=values[i];
     }
   return(min_value);
  }

//+------------------------------------------------------------------+
//| Initialization / Deinitialization                                |
//+------------------------------------------------------------------+
bool IndicatorsInit()
  {
   const string symbol=ActiveSymbol();
   const ENUM_TIMEFRAMES tf=ActiveTimeframe();

   g_atrHandle=iATR(symbol,tf,Inp_ATR_Period);
   if(g_atrHandle==INVALID_HANDLE)
     {
      Print("[Indicators] Failed to create ATR handle. Error: ",GetLastError());
      return(false);
     }
   return(true);
  }

void IndicatorsDeinit()
  {
   if(g_atrHandle!=INVALID_HANDLE)
     {
      IndicatorRelease(g_atrHandle);
      g_atrHandle=INVALID_HANDLE;
     }
  }

//+------------------------------------------------------------------+
//| Calculation                                                      |
//+------------------------------------------------------------------+
bool IndicatorsCalculate(SIndicatorData &data)
  {
   const string symbol=ActiveSymbol();
   const ENUM_TIMEFRAMES tf=ActiveTimeframe();

   if(g_atrHandle==INVALID_HANDLE)
     {
      if(!IndicatorsInit())
         return(false);
     }

   // ATR value from the last completed bar
   double atr_buffer[1];
   if(CopyBuffer(g_atrHandle,0,1,1,atr_buffer)<=0)
     {
      Print("[Indicators] Failed to copy ATR buffer. Error: ",GetLastError());
      return(false);
     }

   // Donchian entry channel (exclude current forming bar)
   double highs_entry[];
   double lows_entry[];
   ArrayResize(highs_entry,Inp_DonchianEntradaPeriod);
   ArrayResize(lows_entry,Inp_DonchianEntradaPeriod);

   int copied_highs=CopyHigh(symbol,tf,1,Inp_DonchianEntradaPeriod,highs_entry);
   int copied_lows=CopyLow(symbol,tf,1,Inp_DonchianEntradaPeriod,lows_entry);
   if(copied_highs<Inp_DonchianEntradaPeriod || copied_lows<Inp_DonchianEntradaPeriod)
     {
      Print("[Indicators] Not enough bars for Donchian entry calculation");
      return(false);
     }

   double highs_exit[];
   double lows_exit[];
   ArrayResize(highs_exit,Inp_DonchianSalidaPeriod);
   ArrayResize(lows_exit,Inp_DonchianSalidaPeriod);

   int copied_highs_exit=CopyHigh(symbol,tf,1,Inp_DonchianSalidaPeriod,highs_exit);
   int copied_lows_exit=CopyLow(symbol,tf,1,Inp_DonchianSalidaPeriod,lows_exit);
   if(copied_highs_exit<Inp_DonchianSalidaPeriod || copied_lows_exit<Inp_DonchianSalidaPeriod)
     {
      Print("[Indicators] Not enough bars for Donchian exit calculation");
      return(false);
     }

   data.atr=atr_buffer[0];
   data.donchianHighEntry=ArrayMaxValue(highs_entry,Inp_DonchianEntradaPeriod);
   data.donchianLowEntry=ArrayMinValue(lows_entry,Inp_DonchianEntradaPeriod);
   data.donchianHighExit=ArrayMaxValue(highs_exit,Inp_DonchianSalidaPeriod);
   data.donchianLowExit=ArrayMinValue(lows_exit,Inp_DonchianSalidaPeriod);
   data.lastCalculation=TimeCurrent();
   return(true);
  }
#endif // __BOTTRADER_INDICATORS_MQH__
//+------------------------------------------------------------------+
