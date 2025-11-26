#pragma once
//+------------------------------------------------------------------+
//| Parameters and configuration                                     |
//+------------------------------------------------------------------+
input string          Inp_Symbol              = "";          // Symbol to trade (empty for current)
input ENUM_TIMEFRAMES Inp_MainTF              = PERIOD_M1;    // Timeframe for signals
input ulong           Inp_Magic               = 56001001;     // Magic number
input string          Inp_TradeComment        = "BotTrader"; // Comment for trades

input bool            Inp_UseSessionFilter    = false;        // Use trading session filter
input int             Inp_SessionStartHour    = 0;
input int             Inp_SessionStartMinute  = 0;
input int             Inp_SessionEndHour      = 23;
input int             Inp_SessionEndMinute    = 59;

input bool            Inp_UseFixedLot         = true;         // Use fixed lot
input double          Inp_FixedLot            = 0.01;         // Fixed lot size
input double          Inp_RiskPercent         = 1.0;          // Risk percent per trade (if not fixed lot)

input double          Inp_MaxDailyLossPct     = 10.0;         // Max daily loss in percent of balance

input int             Inp_SpreadMaximo        = 60;           // Max allowed spread in points
input int             Inp_SlippagePoints      = 50;           // Slippage in points

input int             Inp_DonchianEntradaPeriod = 55;         // Donchian period for entries
input int             Inp_DonchianSalidaPeriod  = 20;         // Donchian period for exits
input bool            Inp_RupturaUsarCierre     = true;       // Use candle close for breakout
input int             Inp_RupturaBufferPuntos   = 100;        // Buffer points above Donchian high

input int             Inp_ATR_Period          = 14;           // ATR period
input double          Inp_ATR_Mult_SL         = 2.0;          // ATR multiplier for stop loss

//+------------------------------------------------------------------+
//| Helper functions                                                 |
//+------------------------------------------------------------------+
string ActiveSymbol()
  {
   if(Inp_Symbol=="")
      return(_Symbol);
   return(Inp_Symbol);
  }

ENUM_TIMEFRAMES ActiveTimeframe()
  {
   return(Inp_MainTF);
  }

bool ValidateParameters()
  {
   bool valid=true;
   if(Inp_DonchianEntradaPeriod<=0)
     {
      Print("Invalid Donchian entry period");
      valid=false;
     }
   if(Inp_DonchianSalidaPeriod<=0)
     {
      Print("Invalid Donchian exit period");
      valid=false;
     }
   if(Inp_ATR_Period<=0)
     {
      Print("Invalid ATR period");
      valid=false;
     }
   if(Inp_SpreadMaximo<=0)
     {
      Print("Invalid maximum spread");
      valid=false;
     }
   return(valid);
  }

bool IsWithinTradingSession()
  {
   if(!Inp_UseSessionFilter)
      return(true);

   MqlDateTime tm;
   TimeToStruct(TimeCurrent(),tm);
   int current_minutes=tm.hour*60+tm.min;
   int start_minutes=Inp_SessionStartHour*60+Inp_SessionStartMinute;
   int end_minutes=Inp_SessionEndHour*60+Inp_SessionEndMinute;

   if(start_minutes<=end_minutes)
      return(current_minutes>=start_minutes && current_minutes<=end_minutes);

   // Overnight session
   return(current_minutes>=start_minutes || current_minutes<=end_minutes);
  }
//+------------------------------------------------------------------+
