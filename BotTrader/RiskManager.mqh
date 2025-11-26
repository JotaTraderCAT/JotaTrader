#pragma once
#include <BotTrader/Parameters.mqh>

//+------------------------------------------------------------------+
//| Initialization / Deinitialization                                |
//+------------------------------------------------------------------+
bool RiskManagerInit()
  {
   return(true);
  }

void RiskManagerDeinit()
  {
  }

//+------------------------------------------------------------------+
//| Spread check                                                     |
//+------------------------------------------------------------------+
bool RiskManagerCheckSpread()
  {
   const string symbol=ActiveSymbol();
   long spread=0;
   if(!SymbolInfoInteger(symbol,SYMBOL_SPREAD,spread))
     {
      Print("[Risk] Failed to get spread for ",symbol,". Error: ",GetLastError());
      return(false);
     }
   if(spread>Inp_SpreadMaximo)
     {
      Print("[Risk] Spread too high: ",spread," > ",Inp_SpreadMaximo);
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Daily loss limit                                                 |
//+------------------------------------------------------------------+
bool RiskManagerCheckDailyLoss()
  {
   if(Inp_MaxDailyLossPct<=0.0)
      return(true);

   datetime now_time=TimeCurrent();
   MqlDateTime tm;
   TimeToStruct(now_time,tm);
   tm.hour=0; tm.min=0; tm.sec=0;
   datetime day_start=StructToTime(tm);

   if(!HistorySelect(day_start,now_time))
     {
      Print("[Risk] HistorySelect failed. Error: ",GetLastError());
      return(true);
     }

   double daily_profit=0.0;
   uint deals_total=HistoryDealsTotal();
   for(uint i=0;i<deals_total;i++)
     {
      ulong deal_ticket=HistoryDealGetTicket(i);
      if(deal_ticket==0)
         continue;

      long magic=HistoryDealGetInteger(deal_ticket,DEAL_MAGIC);
      if(magic!=Inp_Magic)
         continue;

      int entry_type=(int)HistoryDealGetInteger(deal_ticket,DEAL_ENTRY);
      if(entry_type!=DEAL_ENTRY_IN && entry_type!=DEAL_ENTRY_OUT)
         continue;

      double profit=HistoryDealGetDouble(deal_ticket,DEAL_PROFIT)+
                    HistoryDealGetDouble(deal_ticket,DEAL_SWAP)+
                    HistoryDealGetDouble(deal_ticket,DEAL_COMMISSION);
      daily_profit+=profit;
     }

   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double allowed_loss=balance*(Inp_MaxDailyLossPct/100.0)*(-1.0);
   if(daily_profit<=allowed_loss)
     {
      Print("[Risk] Daily loss limit reached. Profit: ",daily_profit," Allowed: ",allowed_loss);
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Stop loss normalization                                          |
//+------------------------------------------------------------------+
double RiskManagerNormalizeStopLoss(const double entry_price,const double sl_price,const bool is_buy)
  {
   const string symbol=ActiveSymbol();
   double normalized_sl=sl_price;

   double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);

   normalized_sl=NormalizeDouble(normalized_sl,digits);

   int stop_level=0;
   if(!SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL,stop_level))
      stop_level=0;

   double min_stop=stop_level*point;
   if(is_buy)
     {
      if(entry_price-normalized_sl<min_stop)
         normalized_sl=entry_price-min_stop;
     }
   else
     {
      if(normalized_sl-entry_price<min_stop)
         normalized_sl=entry_price+min_stop;
     }

   return(normalized_sl);
  }

//+------------------------------------------------------------------+
//| Lot calculation                                                  |
//+------------------------------------------------------------------+
double CalculateLotSize(const double entry_price,const double stop_loss)
  {
   const string symbol=ActiveSymbol();
   double min_lot=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   double max_lot=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   double lot_step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);

   if(Inp_UseFixedLot)
     {
      double lot=NormalizeDouble(Inp_FixedLot,2);
      if(lot<min_lot)
         lot=min_lot;
      if(lot>max_lot)
         lot=max_lot;
      return(lot);
     }

   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_amount=balance*(Inp_RiskPercent/100.0);

   double tick_value=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
   double tick_size=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick_value<=0.0 || tick_size<=0.0)
     {
      Print("[Risk] Invalid tick data for lot calculation");
      return(0.0);
     }

   double stop_distance=entry_price-stop_loss;
   if(stop_distance<=0.0)
     {
      Print("[Risk] Invalid stop distance for lot calculation");
      return(0.0);
     }

   double money_per_point=tick_value/tick_size;
   double stop_points=stop_distance/SymbolInfoDouble(symbol,SYMBOL_POINT);
   if(stop_points<=0.0)
     {
      Print("[Risk] Stop points <= 0");
      return(0.0);
     }

   double lot=risk_amount/(stop_points*money_per_point);
   lot=MathFloor(lot/lot_step)*lot_step;
   lot=NormalizeDouble(lot,2);

   if(lot<min_lot)
      lot=min_lot;
   if(lot>max_lot)
      lot=max_lot;

   return(lot);
  }
//+------------------------------------------------------------------+
