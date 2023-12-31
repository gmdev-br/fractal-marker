//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "Fractal Marker"

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   2

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input ENUM_TIMEFRAMES inputPeriodo = PERIOD_CURRENT;
input string inputAtivo = "";
input int    LevDP = 2;       // Fractal Period or Levels Demar Pint
input int    qSteps = 10;     // Number  Trendlines per UpTrend or DownTrend
input int    BackStep = 0;  // Number of Steps Back
input int    showBars = 3000; // Bars Back To Draw
input int    ArrowCode = 167;
input bool   plotMarkers = false;
input color  buyFractalColor = clrLime;
input color  sellFractalColor = clrRed;
input int    colorFactor = 160;
input int    TrendlineWidth = 3;
input ENUM_LINE_STYLE TrendlineStyle = STYLE_SOLID;
input string  UniqueID  = "TrendLINE"; // Indicator unique ID
input int WaitMilliseconds = 2000;  // Timer (milliseconds) for recalculation
input double fatorLimitador = 1;
input double dolar1 = 5.1574;
input double dolar2 = 5.3952;

double Buf1[], FractalSell[];
double Buf2[], FractalBuy[];
double precoAtual;

string ativo;
int _showBars = showBars;
ENUM_TIMEFRAMES periodo;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {

   ativo = inputAtivo;
   StringToUpper(ativo);
   if (ativo == "")
      ativo = _Symbol;

   periodo = inputPeriodo;

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);

   SetIndexBuffer(0, FractalSell, INDICATOR_DATA);
   ArraySetAsSeries(FractalSell, true);

   SetIndexBuffer(1, FractalBuy, INDICATOR_DATA);
   ArraySetAsSeries(FractalBuy, true);

   SetIndexBuffer(2, Buf1, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(Buf1, true);

   SetIndexBuffer(3, Buf2, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(Buf2, true);

   PlotIndexSetInteger(0, PLOT_ARROW, ArrowCode);
   PlotIndexSetInteger(1, PLOT_ARROW, ArrowCode);

   if (plotMarkers) {
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_ARROW);
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_ARROW);
   } else {
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
   }

   PlotIndexSetInteger(0, PLOT_LINE_COLOR, sellFractalColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, buyFractalColor);

   EventSetMillisecondTimer(WaitMilliseconds);

   ObjectsDeleteAll(0, UniqueID);

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int  reason) {

   delete(_updateTimer);
   ObjectsDeleteAll(0, UniqueID);
   ChartRedraw();

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update() {

   long totalRates = SeriesInfoInteger(ativo, PERIOD_CURRENT, SERIES_BARS_COUNT);
   double onetick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   ArrayInitialize(Buf1, 0.0);
   ArrayInitialize(Buf2, 0.0);
   ArrayInitialize(FractalSell, 0.0);
   ArrayInitialize(FractalBuy, 0.0);

   precoAtual = iClose(ativo, PERIOD_CURRENT, 0);

   static datetime prevTime = 0;
//if(prevTime != iTime(_Symbol, PERIOD_CURRENT, 0)) { // New Bar
   int cnt = 0;
   if(_showBars == 0 || _showBars > totalRates - 1)
      _showBars = totalRates - 1;

   for(cnt = _showBars; cnt > LevDP; cnt--) {
      Buf1[cnt] = DemHigh(cnt, LevDP);
      Buf2[cnt] = DemLow(cnt, LevDP);
      FractalSell[cnt] =  Buf1[cnt];
      FractalBuy[cnt] =  Buf2[cnt];
   }
   for(int i = 0; i < _showBars; i++) {
      if (FractalSell[i] > 0) {
         string name = UniqueID + "_sell_fractal_" + i;
         ObjectCreate(0, name, OBJ_TREND, 0, iTime(ativo, inputPeriodo, i),
                      iHigh(ativo, inputPeriodo, i),
                      iTime(ativo, PERIOD_CURRENT, 0),
                      iHigh(ativo, inputPeriodo, i));
         ObjectSetInteger(0, name, OBJPROP_COLOR, sellFractalColor);
         int k = 0;
      }
   }

   for(int i = 0; i < _showBars; i++) {
      if (FractalBuy[i] > 0) {
         string name = UniqueID + "_buy_fractal_" + i;
         ObjectCreate(0, name, OBJ_TREND, 0, iTime(ativo, inputPeriodo, i),
                      iLow(ativo, inputPeriodo, i),
                      iTime(ativo, PERIOD_CURRENT, 0),
                      iLow(ativo, inputPeriodo, i));
         ObjectSetInteger(0, name, OBJPROP_COLOR, buyFractalColor);
         int k = 0;
      }
   }

//prevTime = iTime(_Symbol, PERIOD_CURRENT, 0);
//}
   ChartRedraw();

   return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      _lastOK = Update();
      //if (debug) Print("Regressão linear híbrida " + " " + _Symbol + ":" + GetTimeFrame(Period()) + " ok");

      EventSetMillisecondTimer(WaitMilliseconds);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TDMain(int Step) {

   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MathRandRange(double x, double y) {
   return(x + MathMod(MathRand(), MathAbs(x - (y + 1))));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DemHigh(int cnt, int sh) {
   if(iHigh(ativo, periodo, cnt) >= iHigh(ativo, periodo, cnt + sh) && iHigh(ativo, periodo, cnt) > iHigh(ativo, periodo, cnt - sh)) {
      if(sh > 1)
         return(DemHigh(cnt, sh - 1));
      else
         return(iHigh(ativo, periodo, cnt));
   } else
      return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DemLow(int cnt, int sh) {
   if(iLow(ativo, periodo, cnt) <= iLow(ativo, periodo, cnt + sh) && iLow(ativo, periodo, cnt) < iLow(ativo, periodo, cnt - sh)) {
      if(sh > 1)
         return(DemLow(cnt, sh - 1));
      else
         return(iLow(ativo, periodo, cnt));
   } else
      return(0);
}

//+------------------------------------------------------------------+

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {

   if(id == CHARTEVENT_CHART_CHANGE) {
      _lastOK = true;
      CheckTimer();
      return;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool _lastOK = false;
MillisecondTimer *_updateTimer;
//+------------------------------------------------------------------+
