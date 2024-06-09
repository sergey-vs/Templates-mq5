#property copyright "Sergey_s_altaya"
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------Include-----------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <GraphicalPanel.mqh>

//+------------------------Inputs------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "=== General Inputs ==="
input long InpMagicNumder  = 12345; // magic number 
input double InpLots       = 0.01;  // lot size
input int InpStopLoss      = 150;   // stop loss in % the range ((0 = off) без стоп лосса)
input int InpTakeProfit    = 200;   // take profit in % the range (( 0 = off) без тейк профита)

input group "=== Range Inputs ==="
input int InpRangeStart    = 600;   // range start time in minutes
input int InpRangeDuration = 120;   // range duration in minutes
input int InpRangeClose    = 1200;  // range close time in minutes ((-1 = off) закрытия позиции не будет)
enum BREAKOUT_MODE_ENUM
{
  ONE_SIGNAL,                       // one breakout per range
  TWO_SIGNALS                       // high and low breakout
};
input BREAKOUT_MODE_ENUM InpBreakoutMode = ONE_SIGNAL; // breakout mode

input group "=== Day of week filter ==="
input bool InpMondey       = true;  // range on mondey
input bool InpTuesday      = true;  // range on tuesday
input bool InpWednesday    = true;  // range on mondey
input bool InpThursday     = true;  // range on thyrsday
input bool InpFriday       = true;   // range on friday

//+------------------------Global variables--------------------------+
//| Global variables                                                 |  
//+------------------------------------------------------------------+

struct RANGE_STRUCT
{
  datetime start_time;   // stert of the range
  datetime end_time;     // end of the range
  datetime close_time;   // close time
  double high;           // high of the range 
  double low;            // low of the range
  bool f_entry;          // flag if we are inside the range
  bool f_high_breakout;  // flag if a high breakout occurred
  bool f_low_breakout;   // flag if a low breakout occurred

  RANGE_STRUCT() : start_time(0), end_time(0), close_time(0), high(0), low(DBL_MAX), f_entry(false), f_high_breakout(false), f_low_breakout(false) {};
 };

  RANGE_STRUCT range;
  MqlTick prevTick, lastTick;
  CTrade trade;
  CGraphicalPanel panel;


//+------------------------Expert initialization function------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
  {
  // chek user inputs
  if(!CheckInputs())
  {
    return INIT_PARAMETERS_INCORRECT;
  }

   // set magicnumber  
   trade.SetExpertMagicNumber(InpMagicNumder);
    
   // calculated new range if inputs changed 
   if (_UninitReason == REASON_PARAMETERS && CountOpenPositions() == 0) 
     {
       CalculateRange();
     }    
 
  // draw objects
  DrawObjects();

  // create panel
  panel.Oninit();

   return(INIT_SUCCEEDED);
  }
  
//+------------------------Expert deinitialization function----------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
  {
    // delete objects
    ObjectsDeleteAll(NULL, "range");

    // destroy panel
    panel.Destroy(reason);
    
  }
  
//+------------------------Expert tick function----------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
  {
   // Get current tick
   prevTick = lastTick;
   SymbolInfoTick(_Symbol, lastTick);

   // range calculation
   if (lastTick.time >= range.start_time && lastTick.time < range.end_time)
      {
       // set flag
       range.f_entry = true;
       // new high
       if (lastTick.ask > range.high)
         {
          range.high = lastTick.ask;
          DrawObjects();  
         }
       // new low   
       if (lastTick.bid < range.low)
         {
          range.low = lastTick.bid;
         DrawObjects();  
         }
       }

   // close position 
   if (InpRangeClose >= 0 && lastTick.time >= range.close_time)
      {
       if (!ClosePositions())
       {
         return;
       }
      }   

   // calculate new range if ...
   if (( (InpRangeClose >= 0 && lastTick.time >= range.close_time)                   // close time reached
      || (range.f_high_breakout && range.f_low_breakout)                             // both breakout flag are true
      || (range.end_time == 0)                                                       // range not calculated yet
      || (range.end_time != 0 && lastTick.time > range.end_time && !range.f_entry ))  //there was a range calculated but no tick inside
      && CountOpenPositions() == 0)
      {
        CalculateRange();
      }

   // check for breakouts
   CheckBreakouts();

  }

//+------------------------Chart event handler-----------------------+
//| Chart event handler                                              |
//+------------------------------------------------------------------+ 
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam){

  panel.PanelChartEvent(id,lparam,dparam,sparam);

}

// chekk user inputs
bool CheckInputs()
 {
   if (InpMagicNumder <= 0)
      {
        Alert("Magicnumber <= 0");
        return false;
      } 

   if (InpLots <= 0 || InpLots >1) 
      {
        Alert("Lots <= 0 or > 1");
        return false;
      } 

   if (InpStopLoss < 0 || InpStopLoss > 1000) 
      {
        Alert("Stop loss < 0 or stop loss > 1000");
        return false;
      } 

   if (InpTakeProfit < 0 || InpTakeProfit > 1000) 
      {
        Alert("Take profit < 0 or Take profit > 1000");
        return false;
      } 

   if (InpRangeClose < 0 && InpStopLoss == 0) 
      {
        Alert("Close time and stop loss is off");
        return false;
      } 

   if (InpRangeStart < 0 || InpRangeStart >= 1440)
      {
        Alert("Range start < 0 or >= 1440");
        return false;
      } 

   if (InpRangeDuration <= 0 || InpRangeDuration >= 1440)
      {
        Alert("Range duration <=0 or >= 1440");
        return false;
      } 

   if (InpRangeClose >= 1440 || (InpRangeStart+InpRangeDuration)%1440 == InpRangeClose)
      {
        Alert("Close time >= 1440 or end time == close time");
        return false;
      } 

   if (InpMondey+InpThursday+InpWednesday+InpThursday+InpFriday == 0)
      {
        Alert("Range is prohibited on all days of the week");
        return false;
      } 

   return true;  

}

//calculate a new range
void CalculateRange()
{
 // reset range variables
 range.start_time = 0;
 range.end_time   = 0;
 range.close_time = 0;
 range.high       = 0.0;
 range.low        = DBL_MAX;
 range.f_entry         = false;
 range.f_high_breakout = false;
 range.f_low_breakout  = false;
 
 // calculate range start time
 int time_cycle   = 86400;
 range.start_time = (lastTick.time - (lastTick.time % time_cycle )) + InpRangeStart*60;
 for (int i = 0; i < 8; i++)
 {
  MqlDateTime tmp;
  TimeToStruct(range.start_time, tmp);
  int dow = tmp.day_of_week;
  if (lastTick.time >= range.start_time || dow == 6 || dow == 0 || (dow == 1 && !InpMondey) || (dow == 2 && !InpTuesday) || (dow == 3 && !InpWednesday) || (dow == 4 && !InpThursday) || (dow == 5 && !InpFriday))
  {
    range.start_time += time_cycle;
  }
 }
 
// calculator range end time
range.end_time = range.start_time + InpRangeDuration*60;
for (int i = 0; i < 2; i++)
{
 MqlDateTime tmp;
  TimeToStruct(range.end_time, tmp);
  int dow = tmp.day_of_week;
  if (dow == 6 || dow == 0)
  {
    range.end_time += time_cycle;
  }
} 

//calculator range close
if (InpRangeClose >= 0)
{
 range.close_time = range.end_time - (range.end_time % time_cycle ) + InpRangeClose*60;
  for (int i = 0; i < 3; i++)
  {
   MqlDateTime tmp;
   TimeToStruct(range.close_time, tmp);
   int dow = tmp.day_of_week;
   if (range.close_time <= range.end_time || dow == 6 || dow == 0)
   {
     range.close_time += time_cycle;
   } 
  }
}
// draw object
DrawObjects();

}

// Count all open positions 
int CountOpenPositions()
{
  int counter = 0;
  int total = PositionsTotal();
  for(int i = total -1; i >=0; i--)
  {
    ulong ticket = PositionGetTicket(i);
    if(ticket <= 0)
    {
      Print("Failed to get position ticket");
      return -1;
    }

    if (!PositionSelectByTicket(ticket))
    {
      Print("Failed to select position by ticket");
      return -1; 
    }
    ulong Magicnumber;
    if (!PositionGetInteger(POSITION_MAGIC, Magicnumber))
    {
      Print("Failed to get position Magicnumber");
      return -1;
    }
    
    if (InpMagicNumder == Magicnumber)
    {
      counter++;
    }  
  }

  return counter;

}

// Check for breakouts
void CheckBreakouts()
{

  // check if we are adter the range end
  if (lastTick.time >= range.end_time && range.end_time > 0 && range.f_entry)
  {
    // check for high breackout
    if (!range.f_high_breakout && lastTick.ask >= range.high)
    {
      range.f_high_breakout =true;
      if (InpBreakoutMode == ONE_SIGNAL)
      {
        range.f_low_breakout = true;
      }
 
      // calculator stop loss and take profit
      double sl = InpStopLoss == 0 ? 0 : NormalizeDouble(lastTick.bid - ((range.high - range.low) * InpStopLoss * 0.01), _Digits);
      double tp = InpTakeProfit == 0 ? 0 : NormalizeDouble(lastTick.bid + ((range.high - range.low) * InpTakeProfit * 0.01), _Digits);

      // open buy position 
      trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLots, lastTick.ask, sl, tp, "Time range EA"); 

    }

    // check for low breackout
    if (!range.f_low_breakout && lastTick.bid <= range.low)
    {
      range.f_low_breakout =true;
      if (InpBreakoutMode == ONE_SIGNAL)
      {
        range.f_high_breakout = true;
      }

      // calculator stop loss and take profit
      double sl =InpStopLoss == 0 ? 0 : NormalizeDouble(lastTick.bid + ((range.high - range.low) * InpStopLoss * 0.01), _Digits);
      double tp =InpTakeProfit == 0 ? 0 : NormalizeDouble(lastTick.bid - ((range.high - range.low) * InpTakeProfit * 0.01), _Digits);

      // open sell position 
      trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLots, lastTick.bid, sl, tp, "Time range EA"); 

    }
    
  }

}

// Close all open positions
bool ClosePositions()
{
  int total = PositionsTotal();
  for (int i = total -1; i >= 0; i--)
  {
    if (total != PositionsTotal())
    {
      total = PositionsTotal();
      i = total;
      continue;
    }

    ulong ticket = PositionGetTicket(i);   // select position
    if (ticket <= 0)
    {
      Print("Failed to get position ticket");
      return false;
    }

    if (!PositionSelectByTicket(ticket))
    {
      Print("False to select position by ticket");
      return false; 
    }

    long Magicnumber;
    if (!PositionGetInteger(POSITION_MAGIC, Magicnumber))
    {
      Print("Failed to get position magicnumber");
      return false;
    } 

    if (Magicnumber == InpMagicNumder)
    {
      trade.PositionClose(ticket);
      if (trade.ResultRetcode() != TRADE_RETCODE_DONE)
      {
        Print("Failed to close position. Result: "+(string)trade.ResultRetcode()+":"+trade.ResultRetcodeDescription());
        return false;
      }
    }
  }
  
  return true;

}

// draw chart objects
void DrawObjects()
{
// start 
 ObjectDelete(NULL, "range start");
 if (range.start_time > 0)
 {
  ObjectCreate(NULL, "range start", OBJ_VLINE, 0, range.start_time, 0);
  ObjectSetString(NULL, "range start", OBJPROP_TOOLTIP, "start of the range \n"+TimeToString(range.start_time, TIME_DATE|TIME_MINUTES));
  ObjectSetInteger(NULL, "range start" , OBJPROP_COLOR, clrYellow);
  ObjectSetInteger(NULL, "range start" , OBJPROP_WIDTH, 2 );
  ObjectSetInteger(NULL, "range start" , OBJPROP_BACK, true);
 }

// end time
 ObjectDelete(NULL, "range end");
 if (range.end_time > 0)
 {
  ObjectCreate(NULL, "range end", OBJ_VLINE, 0, range.end_time, 0);
  ObjectSetString(NULL, "range end", OBJPROP_TOOLTIP, "end of the range \n"+TimeToString(range.end_time, TIME_DATE|TIME_MINUTES));
  ObjectSetInteger(NULL, "range end" , OBJPROP_COLOR, clrYellow);
  ObjectSetInteger(NULL, "range end" , OBJPROP_WIDTH, 2 );
  ObjectSetInteger(NULL, "range end" , OBJPROP_BACK, true);
 }

// close time
 ObjectDelete(NULL, "range close");
 if (range.close_time > 0)
 {
  ObjectCreate(NULL, "range close", OBJ_VLINE, 0, range.close_time, 0);
  ObjectSetString(NULL, "range close", OBJPROP_TOOLTIP, "close of the range \n"+TimeToString(range.close_time, TIME_DATE|TIME_MINUTES));
  ObjectSetInteger(NULL, "range close" , OBJPROP_COLOR, clrRed);
  ObjectSetInteger(NULL, "range close" , OBJPROP_WIDTH, 2 );
  ObjectSetInteger(NULL, "range close" , OBJPROP_BACK, true);
 }

// high
 ObjectsDeleteAll(NULL, "range high");
 if (range.high > 0)
 {
  ObjectCreate(NULL, "range high", OBJ_TREND, 0, range.start_time, range.high, range.end_time, range.high);
  ObjectSetString(NULL, "range high", OBJPROP_TOOLTIP, "high of the range \n"+DoubleToString(range.high, _Digits));
  ObjectSetInteger(NULL, "range high" , OBJPROP_COLOR, clrBlue);
  ObjectSetInteger(NULL, "range high" , OBJPROP_WIDTH, 2 );
  ObjectSetInteger(NULL, "range high" , OBJPROP_BACK, true);
 
  ObjectCreate(NULL, "range high ", OBJ_TREND, 0, range.end_time, range.high, InpRangeClose >= 0 ? range.close_time : INT_MAX, range.high);
  ObjectSetString(NULL, "range high ", OBJPROP_TOOLTIP, "high of the range \n"+DoubleToString(range.high, _Digits));
  ObjectSetInteger(NULL, "range high " , OBJPROP_COLOR, clrBlue);
  ObjectSetInteger(NULL, "range high " ,OBJPROP_BACK, true);
  ObjectSetInteger(NULL, "range high " , OBJPROP_STYLE, STYLE_DOT);
 } 
 
 // low
 ObjectsDeleteAll(NULL, "range low");
 if (range.low < DBL_MAX)
 {
  ObjectCreate(NULL, "range low", OBJ_TREND, 0, range.start_time, range.low, range.end_time, range.low);
  ObjectSetString(NULL, "range low", OBJPROP_TOOLTIP, "high of the range \n"+DoubleToString(range.low, _Digits));
  ObjectSetInteger(NULL, "range low" , OBJPROP_COLOR, clrBlue);
  ObjectSetInteger(NULL, "range low" , OBJPROP_WIDTH, 2 );
  ObjectSetInteger(NULL, "range low" , OBJPROP_BACK, true);
 
 
  ObjectCreate(NULL, "range low ", OBJ_TREND, 0, range.end_time, range.low, InpRangeClose >= 0 ? range.close_time : INT_MAX, range.low);
  ObjectSetString(NULL, "range low ", OBJPROP_TOOLTIP, "low of the range \n"+DoubleToString(range.low, _Digits));
  ObjectSetInteger(NULL, "range low " , OBJPROP_COLOR, clrBlue);
  ObjectSetInteger(NULL, "range low " ,OBJPROP_BACK, true);
  ObjectSetInteger(NULL, "range low " , OBJPROP_STYLE, STYLE_DOT);
 }

 // refresh chart
 ChartRedraw();

}
