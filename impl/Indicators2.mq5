//+------------------------------------------------------------------+
//|                                                          CCI.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"



#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CPositionInfo  tradePosition;                   // trade position object
CTrade tradeLib;

enum TYPE_CANDLE{
   WEAK,
   STRONG,
   HAMMER,
   UNDECIDED,
};

enum OPERATOR{
   EQUAL,
   MAJOR,
   MINOR
};

enum ORIENTATION{
   UP,
   DOWN,
   MEDIUM
};

enum TYPE_NEGOCIATION{
   BUY,
   SELL,
   NONE
};

enum POWER{
   ON,
   OFF
};

enum COORDINATE{
   HORIZONTAL,
   VERTICAL
};

struct CandleInfo {
   ORIENTATION orientation;
   TYPE_CANDLE type;
   double close;
   double open;
   double high;
   double low;
};

struct ResultOperation {
   double total;
   double profits;
   double losses;
   double liquidResult;
   double profitFactor;
   bool instantiated;
};

struct MainCandles {
   MqlRates actual;
   MqlRates last;
   MqlRates secondLast;
   bool instantiated;
};


struct BordersOperation {
   double max;
   double min;
   double central;
   bool instantiated;
   ORIENTATION orientation;
};

struct PeriodProtectionTime {
   string dealsLimitProtection;
   string endProtection;
   string startProtection;
   bool instantiated;
};


input POWER USE_RSI = ON;
input POWER USE_STHOCASTIC = ON;
input POWER EVALUATION_BY_TICK = ON;
input POWER USE_INVERSION = OFF;
input double PERCENT_INVERSION = 90;
input double MULTIPLIER_INVERSION = 2;
input double PERCENT_MOVE_STOP = 50;
input double ACCEPTABLE_SPREAD = 20;
input int PERIOD = 5;
input int PONTUATION_ESTIMATE = 50;
input double ACTIVE_VOLUME = 0.1;
input double TAKE_PROFIT = 2000;
input double STOP_LOSS = 600;
input string SCHEDULE_START_DEALS = "23:20";
input string SCHEDULE_END_DEALS = "01:00";
input string SCHEDULE_START_PROTECTION = "00:00";
input string SCHEDULE_END_PROTECTION = "00:00";
input ulong MAGIC_NUMBER = 111222333444;
input POWER USE_MAGIC_NUMBER = ON;

MqlRates candles[];
datetime actualDay = 0;
bool negociationActive = false;
MqlTick tick;                // variável para armazenar ticks 


double averageJAW[], averageTEETH[], averageLIPS[], averageFrac[], upperFractal[], lowerFractal[], CCI[], RSI[], RVI1[], RVI2[], STHO1[], STHO2[], valuePrice = 0;
int teeth, jaw, lips, handleFractal, fractMedia, handleICCI, handleIRSI, handleIRVI, handleStho, countAverage = 0;
ORIENTATION orientMacro = MEDIUM;
BordersOperation bordersFractal;
bool waitCloseJaw = false;
int periodAval = 3;
//+------------------------------------------------------------------+
//                                                                          | Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      handleIRVI = iRVI(_Symbol,PERIOD_CURRENT,5);
      handleICCI = iCCI(_Symbol,PERIOD_CURRENT,14,PRICE_TYPICAL);
      
      if(USE_STHOCASTIC == ON){
         handleStho=iStochastic(_Symbol,PERIOD_CURRENT,14,3,3,MODE_SMA,STO_LOWHIGH);
      }
      

      if(USE_RSI == ON){
         handleIRSI = iRSI(_Symbol,PERIOD_CURRENT,14,PRICE_CLOSE);
      }
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(!verifyTimeToProtection()){
      int copiedPrice = CopyRates(_Symbol,_Period,0,3,candles);
      if(copiedPrice == 3){
         double spread = candles[periodAval-1].spread;
         if(hasNewCandle()){
            if(!hasPositionOpen()){
               Print("Verificando posicao");
               if(CopyBuffer(handleICCI,0,0,periodAval,CCI) == periodAval && 
                  CopyBuffer(handleIRVI,0,0,periodAval,RVI1) == periodAval && 
                  CopyBuffer(handleIRVI,1,0,periodAval,RVI2) == periodAval){
                  ORIENTATION orientCCI, orientRVI;
                  
                  orientCCI = verifyCCI();
                  orientRVI = verifyRVI();
                  if(orientCCI != MEDIUM && orientCCI == orientRVI  && spread <= ACCEPTABLE_SPREAD){
                     realizeDealIndicators(orientCCI);
                  }
               }
            }else{
               if(USE_INVERSION == ON){
                  invertAllPositions();
               }
               
               if(EVALUATION_BY_TICK == OFF){
                  moveAllPositions(spread);
               }
            }
         }else{
            if(EVALUATION_BY_TICK == ON){
               moveAllPositions(spread);
            }
         }
      }   
    }else{
      Print("Horario de proteção");
      closeAllPositions();
   }
}

void realizeDealIndicators(ORIENTATION orientCCI){
   if(USE_RSI == ON){
      realizeDealsRSI(orientCCI);
   }else{
      if(USE_STHOCASTIC == ON){
         realizeDealsSthocastic(orientCCI);
      }else{
         toBuyOrToSell(orientCCI, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT);
      }
   }
}

void realizeDealsRSI(ORIENTATION orientCCI){    
   if(CopyBuffer(handleIRSI,0,0,periodAval,RSI) == periodAval){
      ORIENTATION orientRSI = verifyRSI();
      if(orientCCI == orientRSI){
         if(USE_STHOCASTIC == ON ){
            realizeDealsSthocastic(orientCCI);
         }else{
            toBuyOrToSell(orientCCI, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT);
         }
      }
   }
}

void realizeDealsSthocastic(ORIENTATION orientCCI){
   if( CopyBuffer(handleStho,0,0,periodAval,STHO1) == periodAval && CopyBuffer(handleStho,1,0,periodAval,STHO2) == periodAval){
      ORIENTATION orientSTHO = verifySTHO(); 
      if(orientCCI == orientSTHO){
         toBuyOrToSell(orientCCI, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT);
      }
   }
}

void invertAllPositions(){
   if(hasPositionOpen()  && verifyMagicNumber()){
      int pos = PositionsTotal() - 1;
      for(int i = pos; i >= 0; i--)  {
         useInversion(PONTUATION_ESTIMATE, i);
      }
   }
}

void moveAllPositions(double spread){
   if(hasPositionOpen()  && verifyMagicNumber()){
      int pos = PositionsTotal() - 1;
      for(int i = pos; i >= 0; i--)  {
         activeStopMovelPerPoints(PONTUATION_ESTIMATE+spread, i);
      }
   }
}
  
ORIENTATION verifyCandleConfirmation(int period) {
   int down = 0, up = 0;
   int copiedPrice = CopyRates(_Symbol,_Period,0,period,candles);
   if(copiedPrice == period){
      for(int i = 0; i < period; i++){
         double points = calcPoints(candles[i].close, candles[i].open);
         if(verifyIfOpenBiggerThanClose(candles[i]) && points > 10){
            down++;
         }else if(!verifyIfOpenBiggerThanClose(candles[i]) && points > 10){
            up++;
         }
      }
   }
   
   if(down > period /2){
      return DOWN;
   }else if(up > period /2){
      return UP;
   }
   
   return MEDIUM;
} 
  
//+------------------------------------------------------------------+

ORIENTATION verifyRVI(){
   if(RVI1[periodAval-1] < RVI2[periodAval-1] && RVI2[periodAval-1] < 0){
      Print("Trend DOWN");
      return DOWN;
   }
   if(RVI1[periodAval-1] > RVI2[periodAval-1] && RVI1[periodAval-1] > 0){
      Print("Trend UP");
      return UP;
   }
   
   if(RVI1[periodAval-1] < RVI2[periodAval-1] && RVI1[periodAval-1] > 0){
      //Print("CORRECTION DOWN");
      return DOWN;
   }
   if(RVI1[periodAval-1] > RVI2[periodAval-1] && RVI2[periodAval-1] < 0){
      //Print("CORRECTION UP");
      return UP;
   }

   return MEDIUM;
}

ORIENTATION verifySTHO(){
   if(STHO1[periodAval-1] >= 80 && STHO2[periodAval-1] >= 70){
      return DOWN;
   }
   if(STHO1[periodAval-1] <= 20 && STHO2[periodAval-1] <= 30){
      return UP;
   }

   return MEDIUM;
}

ORIENTATION verifyRSI(){
   if(RSI[periodAval-1] >= 70 && RSI[0] < 70){
      return DOWN;
   }
   if(RSI[periodAval-1] <= 30 && RSI[0] > 30){
      return UP;
   }

   return MEDIUM;
}

ORIENTATION verifyCCI(){
   if(CCI[periodAval-1] >= 100){
      return DOWN;
   }
   if(CCI[periodAval-1] <= -100){
      return UP;
   }

   return MEDIUM;
}

void useInversion(double points, int position){
   double newSlPrice = 0;
   if(hasPositionOpen()){ 
      double profit = PositionGetDouble(POSITION_PROFIT);
      double pointsInversion =  MathAbs(profit / ACTIVE_VOLUME);
      double stop = (STOP_LOSS < 100 ? STOP_LOSS : 100),  maxLoss = (STOP_LOSS * PERCENT_INVERSION / 100);
      bool inversion = false;
      ORIENTATION orient = MEDIUM;
      
      if(USE_INVERSION == ON && profit < 0){
             orient = verifyCandleConfirmation(PERIOD);
         if(PERCENT_INVERSION > 0 && pointsInversion >= maxLoss){
            inversion = true;
            if(STOP_LOSS - maxLoss > stop){
               stop = STOP_LOSS - maxLoss;
            }
             if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                if(orient == UP){
                   closeBuyOrSell(position);
                   realizeDeals(SELL, ACTIVE_VOLUME*MULTIPLIER_INVERSION, stop, TAKE_PROFIT);
                   return;
                }
             }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                 if(orient == DOWN){
                   closeBuyOrSell(position);
                   realizeDeals(BUY, ACTIVE_VOLUME*MULTIPLIER_INVERSION, stop, TAKE_PROFIT);
                   return;
                }
             }
         }
      }
   }
}

void  activeStopMovelPerPoints(double points, int position = 0){
   double newSlPrice = 0;
   if(hasPositionOpen()){ 
      double tpPrice = PositionGetDouble(POSITION_TP);
      double slPrice = PositionGetDouble(POSITION_SL);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double profit = PositionGetDouble(POSITION_PROFIT);
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      double entryPoints = 0, pointsInversion =  MathAbs(profit / ACTIVE_VOLUME);
      bool modify = false, inversion = false;
      ORIENTATION orient = MEDIUM;
      newSlPrice = slPrice;
      
      
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
         tpPrice = NormalizeDouble((tpPrice + (points * _Point)), _Digits);
         if(slPrice >= entryPrice ){
            entryPoints = calcPoints(slPrice, currentPrice);
            newSlPrice = NormalizeDouble((slPrice + (points * PERCENT_MOVE_STOP / 100 * _Point)), _Digits);
            modify = true;
         }else if(currentPrice > entryPrice){
            entryPoints = calcPoints(entryPrice, currentPrice);
            newSlPrice = entryPrice;
            modify = true;
         }
      }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
         tpPrice = NormalizeDouble((tpPrice - (points * _Point)), _Digits);
         if(slPrice <= entryPrice ){
            entryPoints = calcPoints(slPrice, currentPrice);
            newSlPrice = NormalizeDouble((slPrice - (points * PERCENT_MOVE_STOP / 100 * _Point)), _Digits);
            modify = true;
         }else if(currentPrice < entryPrice){
            entryPoints = calcPoints(entryPrice, currentPrice);
            newSlPrice = entryPrice;
            modify = true;
         }
      }
         
      if(modify == true && entryPoints != 0 && entryPoints >= points){
         tradeLib.PositionModify(PositionGetTicket(position), newSlPrice, tpPrice);
         if(verifyResultTrade()){
            Print("Stop movido");
         }
      }
   }
}
      

double activeStopMovel(double prevPrice, MqlRates& candle){
   if(hasPositionOpen()){
      double tpPrice = PositionGetDouble(POSITION_TP);
      double slPrice = PositionGetDouble(POSITION_SL);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
       /*  if(((entryPrice - actualPrice) / _Point) > STOP_LOSS){
            closeBuyOrSell(0);
         }*/
         
          if(prevPrice == 0){
            prevPrice = entryPrice;
          }
         
          if(prevPrice < candle.close && entryPrice < candle.close){
            double newSlPrice = MathAbs(candle.close - MathAbs((prevPrice-slPrice)));
            prevPrice = candle.close;
            //double newTpPrice = MathAbs(prevPrice + MathAbs((entryPrice-tpPrice)));  
            tradeLib.PositionModify(_Symbol, newSlPrice, tpPrice);
            if(verifyResultTrade()){
               Print("Stop movido");
            }
         }
      }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
       /*  if(((actualPrice - entryPrice) / _Point) > STOP_LOSS){
            closeBuyOrSell(0);
         }*/
         if(prevPrice == 0){
           prevPrice = entryPrice;
         }
          
         if(prevPrice > candle.close && entryPrice > candle.close ){
            double newSlPrice = MathAbs(candle.close + MathAbs((prevPrice-slPrice))); 
            prevPrice = candle.close;
             //double newTpPrice = MathAbs(prevPrice - MathAbs((entryPrice-tpPrice)));  
            tradeLib.PositionModify(_Symbol, newSlPrice, tpPrice);
            if(verifyResultTrade()){
               Print("Stop movido");
            }
         }
      }
   }
   
   return prevPrice;
}
        

BordersOperation normalizeTakeProfitAndStopLoss(double stopLoss, double takeProfit){
   BordersOperation borders;
   // modificação para o indice dolar DOLAR_INDEX
   if(stopLoss != 0 || takeProfit != 0){
      if(_Digits == 3){
         borders.min = (stopLoss * 1000);
         borders.max = (takeProfit * 1000);  
      }else{
         borders.min = NormalizeDouble((stopLoss * _Point), _Digits);
         borders.max = NormalizeDouble((takeProfit * _Point), _Digits); 
      }
   }
   
   return borders;
}

void toBuy(double volume, double stopLoss, double takeProfit){
   SymbolInfoTick(_Symbol, tick);
   double stopLossNormalized = NormalizeDouble((tick.ask - stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.ask + takeProfit), _Digits);
   tradeLib.Buy(volume, _Symbol, NormalizeDouble(tick.ask,_Digits), stopLossNormalized, takeProfitNormalized); 
}

void toSell(double volume, double stopLoss, double takeProfit){
   SymbolInfoTick(_Symbol, tick);
   double stopLossNormalized = NormalizeDouble((tick.bid + stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.bid - takeProfit), _Digits);
   tradeLib.Sell(volume, _Symbol, NormalizeDouble(tick.bid,_Digits), stopLossNormalized, takeProfitNormalized);   
}

bool realizeDeals(TYPE_NEGOCIATION typeDeals, double volume, double stopLoss, double takeProfit){
   if(typeDeals != NONE){
   
      BordersOperation borders = normalizeTakeProfitAndStopLoss(stopLoss, takeProfit); 
      if(hasPositionOpen() == false) {
         if(typeDeals == BUY){ 
            toBuy(volume, borders.min, borders.max);
         }
         else if(typeDeals == SELL){
            toSell(volume, borders.min, borders.max);
         }
         
         if(verifyResultTrade()){
            tradeLib.SetExpertMagicNumber(MAGIC_NUMBER);
            Print("MAGIC NUMBER: " + IntegerToString(MAGIC_NUMBER));
            return true;
         }
       }
    }
    
    return false;
 }

void closeAllPositions(){
   if(hasPositionOpen()){
      int pos = PositionsTotal() - 1;
      for(int i = pos; i >= 0; i--)  {
         closeBuyOrSell(i);
      }
   }
}
  
void closeBuyOrSell(int position){
   if(hasPositionOpen()  && verifyMagicNumber()){
      ulong ticket = PositionGetTicket(position);
      tradeLib.PositionClose(ticket);
      if(verifyResultTrade()){
         Print("Negociação concluída.");
      }
   }
}

bool verifyMagicNumber(){
   ulong magicNumber = tradePosition.Magic();
   if(USE_MAGIC_NUMBER == OFF){
      return true;
   }else{
      if(magicNumber == MAGIC_NUMBER){
         return true;
      }
   }
   return false;
}

bool toBuyOrToSell(ORIENTATION orient, double volume, double stopLoss, double takeProfit){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   return realizeDeals(typeDeal, volume, stopLoss, takeProfit);
   //getHistory();
}

bool hasPositionOpen(){
    if(PositionSelect(_Symbol) == true) {
      return true;       
    }
    
    return false;
}

bool verifyResultTrade(){
   if(tradeLib.ResultRetcode() == TRADE_RETCODE_PLACED || tradeLib.ResultRetcode() == TRADE_RETCODE_DONE){
      printf("Ordem de %s executada com sucesso.");
      return true;
   }else{
      Print("Erro de execução de ordem ", GetLastError());
      ResetLastError();
      return false;
   }
}

BordersOperation drawBorders(double precoAtual, double pontuationEstimateHigh = 0, double pontuationEstimateLow = 0){
   BordersOperation borders;
   /*
   int numCandles = 2;
   int copiedPrice = CopyRates(_Symbol,_Period,0,numCandles,candles);
   if(copiedPrice == numCandles){
      for(int i = 0; i < numCandles; i++){
         pontuationEstimateHigh += (candles[i].high) ;
         pontuationEstimateLow += (candles[i].low);
      }
      pontuationEstimateHigh = pontuationEstimateHigh /numCandles;
      pontuationEstimateLow = pontuationEstimateLow /numCandles;
      borders.max = MathAbs(_Point * pontuationEstimateHigh + precoAtual);
      borders.min = MathAbs(_Point * pontuationEstimateLow - precoAtual);
   }*/
   
   borders.max = MathAbs(_Point * pontuationEstimateHigh + precoAtual);
   borders.min = MathAbs(_Point * pontuationEstimateLow - precoAtual);
  
   drawHorizontalLine(borders.max, 0, "BorderMax", clrYellow);
   drawHorizontalLine(borders.min, 0, "BorderMin", clrYellow);
   //Print("Atualização de Bordas");
   
   return borders;
}

bool hasNewCandle(){
   static datetime lastTime = 0;
   
   datetime lastBarTime = (datetime)SeriesInfoInteger(Symbol(),PERIOD_CURRENT,SERIES_LASTBAR_DATE);
   
   //primeira chamada da funcao
   if(lastTime == 0){
      lastTime = lastBarTime;
      return false;
   }
   
   if(lastTime != lastBarTime){
      lastTime = lastBarTime;
      return true;
   }
   
   return false;
}

void drawHorizontalLine(double price, datetime time, string nameLine, color indColor){
   ObjectCreate(ChartID(),nameLine,OBJ_HLINE,0,time,price);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
   ObjectMove(ChartID(),nameLine,0,time,price);
}

void drawArrow(datetime time, string nameLine, double price, ORIENTATION orientation, color indColor){
   if(orientation == UP){
      ObjectCreate(ChartID(),nameLine,OBJ_ARROW_UP,0,time,price);
      ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   }else{
      ObjectCreate(ChartID(),nameLine,OBJ_ARROW_DOWN,0,time,price);
      ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   }
}

void drawVerticalLine(datetime time, string nameLine, color indColor){
   ObjectCreate(ChartID(),nameLine,OBJ_VLINE,0,time,0);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
}

void createButton(string nameLine, int xx, int yy, int largura, int altura, int canto, int tamanho, string fonte, string text, long corTexto, long corFundo, long corBorda, bool oculto){
   ObjectCreate(ChartID(),nameLine,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,nameLine,OBJPROP_XDISTANCE,xx);
   ObjectSetInteger(0,nameLine,OBJPROP_YDISTANCE, yy);
   ObjectSetInteger(0,nameLine,OBJPROP_XSIZE, largura);
   ObjectSetInteger(0,nameLine,OBJPROP_YSIZE, altura);
   ObjectSetInteger(0,nameLine,OBJPROP_CORNER, canto);
   ObjectSetInteger(0,nameLine,OBJPROP_FONTSIZE, tamanho);
   ObjectSetString(0,nameLine,OBJPROP_FONT, fonte);
   ObjectSetString(0,nameLine,OBJPROP_TEXT, text);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR, corTexto);
   ObjectSetInteger(0,nameLine,OBJPROP_BGCOLOR, corFundo);
   ObjectSetInteger(0,nameLine,OBJPROP_BORDER_COLOR, corBorda);
}

bool verifyTimeToProtection(){
   datetime now = TimeCurrent();
   bool timeDeals = timeToProtection(SCHEDULE_START_DEALS, SCHEDULE_END_DEALS);
   bool timeProtect = timeToProtection(SCHEDULE_START_PROTECTION, SCHEDULE_END_PROTECTION);
   if(timeDeals || timeProtect){
     // Print("Horario de proteção ativo");
      return true;
   }
   
   return false;
}

bool timeToProtection(string startTime, string endTime){
   datetime now = TimeCurrent();
   datetime start = StringToTime(startTime);
   datetime end = StringToTime(endTime);
   
   if(startTime == "00:00" && endTime == "00:00"){
      return false;
   }else{
      if(now > start && now < end){
         return true;
      }
   }
   
   return false;
}

bool verifyIfOpenBiggerThanClose(MqlRates& candle){
   return candle.open > candle.close;
}

void removeDeals(){
   Print("Removendo negociações..");
   Print("Posições em aberto: ", PositionsTotal());
   while(PositionsTotal() > 0 || hasPositionOpen()){
      closeBuyOrSell(0);
   }
}
  // countDays = verifyDayTrade(timeStartedDealActual, countDays, 0);
  

ORIENTATION getOrientationPerCandles(MqlRates& prev, MqlRates& actual){
   if(actual.open > prev.open){
      return UP;
   }else if(actual.open < prev.open){
      return DOWN;
   }
   
   return MEDIUM;
}


MainCandles generateMainCandles(){
   MainCandles mainCandles;
   int copiedPrice = CopyRates(_Symbol,_Period,0,3,candles);
   if(copiedPrice == 3){
      mainCandles.actual = candles[2];
      mainCandles.last = candles[1];
      mainCandles.secondLast = candles[0];
      mainCandles.instantiated = true;
   }else{
      mainCandles.instantiated = false;
   }
   
   return mainCandles;
}

bool isNewDay(datetime startedDatetimeRobot){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(startedDatetimeRobot, structDate);
   
   if((structActual.day_of_year - structDate.day_of_year) > 0){
      return true;
   }else{
      return false;
   }
}

int getActualDay(datetime startedDatetimeRobot){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(startedDatetimeRobot, structDate);
   return (structActual.day_of_year - structDate.day_of_year);
}

double calcPoints(double val1, double val2, bool absValue = true){
   if(absValue){
      return MathAbs(val1 - val2) / _Point;
   }else{
      return (val1 - val2) / _Point;
   }
}

void instanciateBorder(BordersOperation& borders){
     borders.max = 0;
     borders.min = 0;
     borders.central = 0;
     borders.instantiated = false;
     borders.orientation = MEDIUM;
}
