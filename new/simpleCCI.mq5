//+------------------------------------------------------------------+
//|                                                          CCI.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"



#include <Trade\Trade.mqh>
CTrade tradeLib;

enum AVERAGE_PONTUATION{
   AVERAGE_0,
   AVERAGE_5,
   AVERAGE_10,
   AVERAGE_15,
   AVERAGE_20,
   AVERAGE_25,
   AVERAGE_30,
};

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
   ORIENTATION actualOrientation;
   ORIENTATION lastOrientation;
   ORIENTATION secondLastOrientation;
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


input int PERIOD = 5;
input double ACTIVE_VOLUME = 1.0;
input double LOSS_PER_DAY = 0;
input double PROFIT_PER_DAY = 0;
input string SCHEDULE_START_PROTECTION = "00:00";
input string SCHEDULE_END_PROTECTION = "00:00";

MqlRates candles[];
datetime actualDay = 0;
bool negociationActive = false;
MqlTick tick;                // variável para armazenar ticks 


double CCI[], valuePrice = 0;
int handleICCI, countAverage = 0;
ORIENTATION orientMacro = MEDIUM;
int periodAval = 3;
//+------------------------------------------------------------------+
//                                                                          | Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   handleICCI = iCCI(_Symbol,PERIOD_CURRENT,14,PRICE_TYPICAL);
   return(INIT_SUCCEEDED);
}
  
void OnTick() {

   if(verifyTimeToProtection()){
      int copiedPrice = CopyRates(_Symbol,_Period,0,3,candles);
      if(copiedPrice == 3){
         if(!hasPositionOpen()){
            if(CopyBuffer(handleICCI,0,0,periodAval,CCI) == periodAval && candles[periodAval-1].spread <= 15){
               MainCandles mainCandles = generateMainCandles();
               double actualCCI = CCI[periodAval-3];
               double lastCCI = CCI[periodAval-2];
               double secondLastCCI = CCI[periodAval-1];
               
               if(mainCandles.secondLastOrientation == UP &&  secondLastCCI >= 100) {
                  if(mainCandles.lastOrientation == UP &&  lastCCI >= 100) {
                     if(mainCandles.actualOrientation == DOWN &&  actualCCI < 100) {
                        if(mainCandles.actual.close < mainCandles.last.low) {
                           double max = mainCandles.last.high > mainCandles.secondLast.high ? mainCandles.last.high : mainCandles.secondLast.high;
                           max = max > mainCandles.actual.high ? max : mainCandles.actual.high;
                           
                           double take = calcPoints(mainCandles.secondLast.open, mainCandles.actual.close, true);
                           double stop = calcPoints(max, mainCandles.actual.close, true);
                           //if(stop <= take) {
                              toBuyOrToSell(DOWN, ACTIVE_VOLUME, stop, take);
                           //}
                        }
                     }
                  }               
               }
               else if(mainCandles.secondLastOrientation == DOWN &&  secondLastCCI <= -100) {
                  if(mainCandles.lastOrientation == DOWN && lastCCI <= -100) {
                     if(mainCandles.actualOrientation == UP &&  actualCCI > -100) {
                        if(mainCandles.actual.close > mainCandles.last.high) {
                           double max = mainCandles.last.high > mainCandles.secondLast.high ? mainCandles.last.high : mainCandles.secondLast.high;
                           max = max > mainCandles.actual.high ? max : mainCandles.actual.high;
                          
                           double take = calcPoints(mainCandles.secondLast.open, mainCandles.actual.close, true);
                           double stop = calcPoints(max, mainCandles.actual.close, true);
                           //if(stop <= take) {
                              toBuyOrToSell(UP, ACTIVE_VOLUME, stop, take);
                           //}
                        }
                     }
                  }               
               }
            }
         }
      }   
   }
}
//+------------------------------------------------------------------+
 
ORIENTATION getCandleOrientantion(MqlRates& candle){
   if(candle.close > candle.open) {
      return UP;
   }
   else if(candle.close < candle.open) {
      return DOWN;
   }
   
   return MEDIUM;
}

ResultOperation getResultOperation(double result){
   ResultOperation resultOperation;
   resultOperation.total = 0;
   resultOperation.losses = 0;
   resultOperation.profits = 0;
   resultOperation.liquidResult = 0;
   resultOperation.profitFactor = 0;
   
   resultOperation.total += result; 
   
   if(result > 0){
      resultOperation.profits += result;
   }
   
   if(result < 0){
      resultOperation.losses += (-result);
   }
   
   resultOperation.liquidResult = resultOperation.profits - resultOperation.losses;
   //Definir fator de lucro
   if(resultOperation.losses > 0){
      resultOperation.profitFactor = resultOperation.profits / resultOperation.losses;
   }else{
      resultOperation.profitFactor = -1;
   }
   
   return resultOperation;
}

int verifyDayTrade(datetime timeStarted, int countDays, double liquidResult){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   //if(countDays == 1 && timeStarted == 0){
   //   timeStarted = TimeCurrent();
   //}
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(timeStarted, structDate);
   if(structDate.day_of_year != structActual.day_of_year){
      countDays++; 
      Print("Ganho do dia -> R$", DoubleToString(liquidResult, 2));
      Print("Negociações Encerradas para o dia: ", TimeToString(timeStarted, TIME_DATE));
      Print("Negociações Abertas para o dia: ", TimeToString(actualTime, TIME_DATE));
      timeStarted = actualTime;
   }
   
   return countDays;
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
            //Print("Negociação realizada com sucesso.");
            return true;
         }
       }
    }
    
    return false;
 }

void closeBuyOrSell(int position){
   if(hasPositionOpen()){
      ulong ticket = PositionGetTicket(position);
      tradeLib.PositionClose(ticket);
      if(verifyResultTrade()){
         Print("Negociação concluída.");
      }
   }
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

bool verifyTimeToProtection(){
   if(timeToProtection(SCHEDULE_START_PROTECTION, SCHEDULE_END_PROTECTION)){
     // Print("Horario de proteção ativo");
      return false;
   }
   return true;
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


double calcTotal(){
   double total = 0;
   ResultOperation resultOp;
   double result = 0;
   
   HistorySelect(0, TimeCurrent());
   ulong trades = HistoryDealsTotal();
   //Print("Total de negociações: ", trades);
   //Print("Lucro Atual: R$ ", resultOperation.liquidResult);
   
   for(uint i = 1; i <= trades; i++)  {
      ulong ticket = HistoryDealGetTicket(i);
      result = HistoryDealGetDouble(ticket,DEAL_PROFIT);    
      resultOp = getResultOperation(result);   
      total += resultOp.liquidResult; 
   }
   
   return total;
}

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
      mainCandles.actualOrientation = getCandleOrientantion(candles[2]);
      mainCandles.lastOrientation = getCandleOrientantion(candles[1]);
      mainCandles.secondLastOrientation = getCandleOrientantion(candles[0]);
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

//return true se atingiu o ganho ou perda diario;
bool verifyResultPerDay(double result ){
   if(LOSS_PER_DAY > 0 && PROFIT_PER_DAY > 0){
      if(result > PROFIT_PER_DAY || (-result) > LOSS_PER_DAY){
         return true;
      }
   }
   
   return false;
}

void instanciateBorder(BordersOperation& borders){
     borders.max = 0;
     borders.min = 0;
     borders.central = 0;
     borders.instantiated = false;
     borders.orientation = MEDIUM;
}