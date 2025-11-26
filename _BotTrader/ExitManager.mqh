//+------------------------------------------------------------------+
//| Exit management module                                           |
//+------------------------------------------------------------------+
#ifndef __BOTTRADER_EXIT_MQH__
#define __BOTTRADER_EXIT_MQH__

#include <_BotTrader/Parameters.mqh>
#include <_BotTrader/IndicatorsModule.mqh>
#include <_BotTrader/TradeManager.mqh>
#include <_BotTrader/RiskManager.mqh>

//+------------------------------------------------------------------+
//| Initialization / Deinitialization                                |
//+------------------------------------------------------------------+
bool ExitManagerInit()
  {
   return(true);
  }

void ExitManagerDeinit()
  {
  }

//+------------------------------------------------------------------+
//| Exit handling                                                    |
//+------------------------------------------------------------------+
void ManageOpenPosition(const SIndicatorData &data)
  {
   if(!HasOpenPosition())
      return;

   const string symbol=ActiveSymbol();
   const ENUM_TIMEFRAMES tf=ActiveTimeframe();
   double point=SymbolInfoDouble(symbol,SYMBOL_POINT);

   if(!g_position.Select(symbol))
      return;

   if(g_position.Magic()!=(long)Inp_Magic)
      return;

   double current_sl=g_position.StopLoss();

   double closes[1];
   if(CopyClose(symbol,tf,1,1,closes)<=0)
     {
      Print("[Exit] Failed to copy close price. Error: ",GetLastError());
      return;
     }

   double exit_level=data.donchianLowExit - (Inp_RupturaBufferPuntos*point);
   if(closes[0]<exit_level)
     {
      ClosePosition("Donchian exit");
      return;
     }

   double atr_based_sl=g_position.PriceOpen() - (data.atr*Inp_ATR_Mult_SL);
   atr_based_sl=RiskManagerNormalizeStopLoss(g_position.PriceOpen(),atr_based_sl,true);

   if(atr_based_sl>current_sl)
     {
      UpdateStopLoss(atr_based_sl);
     }
  }
#endif // __BOTTRADER_EXIT_MQH__
//+------------------------------------------------------------------+
