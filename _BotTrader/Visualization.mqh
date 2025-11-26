//+------------------------------------------------------------------+
//| Visualization module                                             |
//+------------------------------------------------------------------+
#ifndef __BOTTRADER_VISUALIZATION_MQH__
#define __BOTTRADER_VISUALIZATION_MQH__

#include <_BotTrader/Parameters.mqh>
#include <_BotTrader/IndicatorsModule.mqh>

//+------------------------------------------------------------------+
//| Visualization                                                    |
//+------------------------------------------------------------------+
void VisualizationInit()
  {
  }

void VisualizationDeinit()
  {
   Comment("");
  }

void VisualizationUpdate(const SIndicatorData &data)
  {
   string text;
   text+="Donchian Entry High: "+DoubleToString(data.donchianHighEntry,_Digits)+"\n";
   text+="Donchian Entry Low : "+DoubleToString(data.donchianLowEntry,_Digits)+"\n";
   text+="Donchian Exit Low  : "+DoubleToString(data.donchianLowExit,_Digits)+"\n";
   text+="ATR ("+IntegerToString(Inp_ATR_Period)+"): "+DoubleToString(data.atr,_Digits)+"\n";
   text+="Magic: "+IntegerToString((int)Inp_Magic)+" Comment: "+Inp_TradeComment;
   Comment(text);
  }
#endif // __BOTTRADER_VISUALIZATION_MQH__
//+------------------------------------------------------------------+
