//+------------------------------------------------------------------+
//| Signals module                                                   |
//+------------------------------------------------------------------+
#ifndef __BOTTRADER_SIGNALS_MQH__
#define __BOTTRADER_SIGNALS_MQH__

#include <_BotTrader/Parameters.mqh>
#include <_BotTrader/IndicatorsModule.mqh>

//+------------------------------------------------------------------+
//| Signal enumeration                                               |
//+------------------------------------------------------------------+
enum ESignalAction
  {
   SIGNAL_NONE=0,
   SIGNAL_BUY=1
  };

//+------------------------------------------------------------------+
//| Initialization / Deinitialization                                |
//+------------------------------------------------------------------+
bool SignalsInit()
  {
   return(true);
  }

void SignalsDeinit()
  {
  }

//+------------------------------------------------------------------+
//| Signal evaluation                                                |
//+------------------------------------------------------------------+
ESignalAction CheckEntrySignal(const SIndicatorData &data)
  {
    const string symbol=ActiveSymbol();
    const ENUM_TIMEFRAMES tf=ActiveTimeframe();
    double point=0.0;
    if(!SymbolInfoDouble(symbol,SYMBOL_POINT,point))
      {
       Print("[Signals] Failed to obtain point size for ",symbol,". Error: ",GetLastError());
       return(SIGNAL_NONE);
      }

   double price_source=0.0;
   if(Inp_RupturaUsarCierre)
     {
      double closes[1];
      if(CopyClose(symbol,tf,1,1,closes)<=0)
        {
         Print("[Signals] Failed to copy close price. Error: ",GetLastError());
         return(SIGNAL_NONE);
        }
      price_source=closes[0];
     }
    else
      {
       double ask=0.0;
       if(!SymbolInfoDouble(symbol,SYMBOL_ASK,ask))
         {
          Print("[Signals] Failed to copy ask price. Error: ",GetLastError());
          return(SIGNAL_NONE);
         }
       price_source=ask;
      }

   double breakout_level=data.donchianHighEntry + (Inp_RupturaBufferPuntos*point);
   if(price_source>breakout_level)
      return(SIGNAL_BUY);

   return(SIGNAL_NONE);
  }
#endif // __BOTTRADER_SIGNALS_MQH__
//+------------------------------------------------------------------+
