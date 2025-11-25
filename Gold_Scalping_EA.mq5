//+------------------------------------------------------------------+
//|                                                  Gold_Scalping_EA|
//|                       Donchian Long-Only Scalping (v1.3)         |
//+------------------------------------------------------------------+
#property copyright "BotTrader"
#property version   "1.30"
#property strict

#include <BotTrader/Parameters.mqh>
#include <BotTrader/IndicatorsModule.mqh>
#include <BotTrader/SignalsModule.mqh>
#include <BotTrader/RiskManager.mqh>
#include <BotTrader/TradeManager.mqh>
#include <BotTrader/ExitManager.mqh>
#include <BotTrader/Visualization.mqh>

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!ValidateParameters())
     {
      return(INIT_FAILED);
     }

   if(!IndicatorsInit())
     {
      Print("[Init] Error initializing indicators");
      return(INIT_FAILED);
     }

   if(!SignalsInit())
     {
      Print("[Init] Error initializing signals module");
      return(INIT_FAILED);
     }

   if(!RiskManagerInit())
     {
      Print("[Init] Error initializing risk manager");
      return(INIT_FAILED);
     }

   if(!TradeManagerInit())
     {
      Print("[Init] Error initializing trade manager");
      return(INIT_FAILED);
     }

   if(!ExitManagerInit())
     {
      Print("[Init] Error initializing exit manager");
      return(INIT_FAILED);
     }

   VisualizationInit();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   VisualizationDeinit();
   ExitManagerDeinit();
   TradeManagerDeinit();
   RiskManagerDeinit();
   SignalsDeinit();
   IndicatorsDeinit();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsWithinTradingSession())
      return;

   if(!RiskManagerCheckDailyLoss())
      return;

   SIndicatorData indicator_data;
   if(!IndicatorsCalculate(indicator_data))
      return;

   ManageOpenPosition(indicator_data);

   if(HasOpenPosition())
     {
      VisualizationUpdate(indicator_data);
      return;
     }

   if(!RiskManagerCheckSpread())
      return;

   ESignalAction signal=CheckEntrySignal(indicator_data);
   if(signal!=SIGNAL_BUY)
     {
      VisualizationUpdate(indicator_data);
      return;
     }

   const string symbol=ActiveSymbol();
   const double ask=SymbolInfoDouble(symbol,SYMBOL_ASK);

   double stop_loss=ask-(indicator_data.atr*Inp_ATR_Mult_SL);
   stop_loss=RiskManagerNormalizeStopLoss(ask,stop_loss,true);

   double lot=CalculateLotSize(ask,stop_loss);
   if(lot<=0.0)
     {
      VisualizationUpdate(indicator_data);
      return;
     }

   if(OpenBuy(lot,stop_loss,0.0))
     {
      VisualizationUpdate(indicator_data);
     }
  }
//+------------------------------------------------------------------+
