//+------------------------------------------------------------------+
//|                                                       robot1.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>

CTrade tradeLib;

#define LOW 0
#define HIGH 1
#define CLOSE 2
#define OPEN 3

enum AVERAGE_PONTUATION{
   AVERAGE_0,
   AVERAGE_5,
   AVERAGE_10,
   AVERAGE_15,
   AVERAGE_20,
   AVERAGE_25,
   AVERAGE_30,
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


struct InfoDeal {
   double price;
   ulong ticket;
   datetime timeStartDeal;
};


struct ResultOperation {
   double total;
   double profits;
   double losses;
   double liquidResult;
   double profitFactor;
};

struct BordersOperation {
   double max;
   double min;
};

struct SelectedPrices {
   MqlRates last;
   MqlRates secondLast;
};


struct FinishDeal {
   bool gain;
   double open;
   double close;
   TYPE_NEGOCIATION type;
};

input POWER TESTING_DAY = ON;
 POWER CONNECT_AI = OFF;
input POWER AGAINST_CURRENT = ON;
input POWER SCALPER = ON;
input POWER STOP_MOVEL = ON;
input AVERAGE_PONTUATION RANDOM_PONTUATION = AVERAGE_0;
input POWER BASED_ON_FINANCIAL_PROFIT_AND_LOSS = ON;
input int PONTUATION_ESTIMATE = 100;
input double PROFIT_MAX_PER_DAY = 300.0;
input double LOSS_MAX_PER_DAY = 50.0;
input int TAKE_PROFIT = 110;
input int STOP_LOSS = 40;
input double ACTIVE_VOLUME = 1.0;
input int BARS_NUM = 4;
input int HEGHT_BUTTON_PANIC = 350;
input int WIDTH_BUTTON_PANIC = 500;
input string NEGOCIATIONS_LIMIT_TIME = "17:30";
input string START_PROTECTION_TIME = "12:00";
input string END_PROTECTION_TIME = "13:00";

MqlRates candles[];
MqlTick tick;

double takeProfit = (TAKE_PROFIT);
double stopLoss = (STOP_LOSS);

int contador = 0;
int countDays = 1;
bool advanceDeal = false;
datetime avaliationTime;
bool periodAchieved = false;
int printClosedNeg = false;
bool activeDeal = false;
bool startedAvaliationTime = false;
SelectedPrices selectedPrices;
datetime dateClosedDeal;
bool closedDeals = false;
bool isPossivelToSell = false;
int maxPositionsArray = 2;
BordersOperation borders;
bool waitNewPeriod = false;
bool hasAllPeriod = false;
double profits = 0;
double losses = 0;
InfoDeal infoDeal;
datetime timeStarted;
ORIENTATION goToNewCandle = MEDIUM;
   
bool activatedPeakRobot = false;
bool activatedBorderRobot = false;
int printTimeProtect = true;
int printEndTimeDeal = true;
ResultOperation resultDeals;
double percentProfitOrLoss = 0.4;
double percentPontuationEstimate = 0.6;

int countFinishedDeals = 0;
FinishDeal finishedDeals[15];

void startRobots(){
  printf("Start Robots in " +  _Symbol);
  Print("Negociações Abertas para o dia: ", TimeToString(TimeCurrent(), TIME_DATE));
  createButton("BotaoPanic", WIDTH_BUTTON_PANIC, HEGHT_BUTTON_PANIC, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Negociacoes", clrWhite, clrRed, clrRed, false);
}

void finishRobots(){
  printf("Finish Robots in " +  _Symbol);
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

void getHistory(){
   ResultOperation resultOperation, resultOp;
   double result = 0;
   
   HistorySelect(0, TimeCurrent());
   ulong trades = HistoryDealsTotal();
   //Print("Total de negociações: ", trades);
   //Print("Lucro Atual: R$ ", resultOperation.liquidResult);
   
   for(uint i = 1; i <= trades; i++)  {
      ulong ticket = HistoryDealGetTicket(i);
      result = HistoryDealGetDouble(ticket,DEAL_PROFIT);    
      resultOp = getResultOperation(result);
      resultOperation.total += resultOp.total;
      resultOperation.losses += resultOp.losses;
      resultOperation.profits += resultOp.profits;
      resultOperation.liquidResult += resultOp.liquidResult;
      resultOperation.profitFactor += resultOp.profitFactor;  
   }
   
   Comment("Trades: " + IntegerToString(trades), 
   " Profits: " + DoubleToString(resultOperation.profits, 2), 
   " Losses: " + DoubleToString(resultOperation.losses, 2), 
   " Profit Factor: " + DoubleToString(resultOperation.profitFactor, 2), 
   " Liquid Result: " + DoubleToString(resultOperation.liquidResult, 2),
   " Number of days: " + IntegerToString(countDays));
   
   resultDeals.losses = resultOperation.losses;
   resultDeals.profits = resultOperation.profits;
   resultDeals.profitFactor = resultOperation.profitFactor;
   resultDeals.liquidResult = resultOperation.liquidResult;
      
   if(TESTING_DAY == ON){
      if(resultDeals.liquidResult >= PROFIT_MAX_PER_DAY || resultDeals.liquidResult <= -LOSS_MAX_PER_DAY ) {
        Print("Limite atingido por dia -> R$ ", resultDeals.liquidResult);
        toCloseDeals();
      } 
   }
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

bool timeToProtection(string protectionTime, OPERATOR oper){
   string actualTime = TimeToString(TimeCurrent(),TIME_MINUTES);
   
   if(protectionTime == "00:00"){
      return false;
   }else{
      if(oper == MINOR){
         if(actualTime <= protectionTime){
            return true;
         }
      }
      if(oper == MAJOR){
         if(actualTime >= protectionTime){
            return true;
         }
      }else{
         if(actualTime == protectionTime){
            return true;
         }
      }
   }
   
   return false;
}

// retorna um booleano indicando se continua a negociacao(false) ou fecha a negociação(true)
bool loadAI(){
   if(CONNECT_AI == ON){
      MqlRates precos[1];
      int copied = CopyRates(_Symbol,_Period,0, 1, precos);
      if(copied == 1){
         FinishDeal deal = finishedDeals[countFinishedDeals];
         deal.close = candles[0].close;
         
         if(deal.type == BUY){
            deal.gain = deal.open <= deal.close;
         } 
         if(deal.type == SELL){
            deal.gain = deal.open >= deal.close;
         }
         finishedDeals[countFinishedDeals] = deal;
      }
      
      if(countFinishedDeals >= BARS_NUM){
         FinishDeal lastDeal = finishedDeals[countFinishedDeals];
         int countTypeDeals = 0, countLossDeals = 0;
         for(int i = 0; i < countFinishedDeals; i++){
            FinishDeal deal = finishedDeals[i];
            if(deal.type == lastDeal.type){
               countTypeDeals++;
               if(deal.gain == false){
                  countLossDeals++;
               }
            }
         }  
         
         // o numero de perda é maior que a media das negociacoes
         int media = countTypeDeals / 2;
         if(media > 1 && countLossDeals > media){
            return lastDeal.gain;
         }
      }
   }
      
   return true;
}

void closeBuyOrSell(){
   bool continueClose = loadAI();
   
   if(continueClose == true){
      ulong ticket = PositionGetTicket(0);
      tradeLib.PositionClose(ticket);
      if(verifyResultTrade()){
         if(CONNECT_AI == ON){
            countFinishedDeals++;
            if(countFinishedDeals > 14){
               countFinishedDeals = 14;
               for(int i = 0; i < countFinishedDeals; i++){
                  finishedDeals[i] = finishedDeals[i+1];
               }
            }
         }
      }
   }
}

void decideToBuyOrSellPerCandle(ORIENTATION orient){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   realizeDeals(typeDeal, ACTIVE_VOLUME);
   //getHistory();
}

ORIENTATION verifyOrientation(){
   if(hasNewCandle()){
      if(waitNewPeriod == false) {
         ulong numBars = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
         int barsPrevActualCandle = BARS_NUM - 1;
         int copied = CopyRates(_Symbol,_Period,0, BARS_NUM, candles);
         if(copied == BARS_NUM && barsPrevActualCandle > 0){
            int up = 0, down = 0;
            MqlRates lastCandle = candles[barsPrevActualCandle], prevCandle, nextCandle;
            double maxPrice = candles[0].high, minPrice = candles[0].low;
            double prevHigh = 0, prevLow = 0, nextHigh = 0, nextLow = 0, secPrevLow = 0, secPrevHigh = 0;
            BordersOperation averagePontuation;
            averagePontuation.max = 0;
            averagePontuation.min = 0;
            
            for(int i = 0; i < barsPrevActualCandle; i++){
               prevCandle = candles[i];
               nextCandle = candles[i+1];
               averagePontuation.max += prevCandle.high;
               averagePontuation.min += prevCandle.low;
               if(i-1 >= 0){
                  if(candles[i-1].open > candles[i-1].close){
                     secPrevHigh = MathAbs(candles[i-1].open + candles[i-1].high) / 2;
                     secPrevLow = MathAbs(candles[i-1].close + candles[i-1].low) / 2;
                  }else{
                     secPrevLow =  MathAbs(candles[i-1].open + candles[i-1].low) / 2;
                     secPrevHigh = MathAbs(candles[i-1].close + candles[i-1].high) / 2;
                  }
                  
                  if(secPrevHigh > prevHigh || secPrevLow > prevLow){
                     up--;
                  }
                  if(secPrevHigh < prevHigh || secPrevLow < prevLow){
                     down--;
                  }
               }
               
               if(prevCandle.open > prevCandle.close){
                  prevHigh = MathAbs(prevCandle.open + prevCandle.high) / 2;
                  prevLow = MathAbs(prevCandle.close + prevCandle.low) / 2;
               }else{
                  prevLow =  MathAbs(prevCandle.open + prevCandle.low) / 2;
                  prevHigh = MathAbs(prevCandle.close + prevCandle.high) / 2;
               }
               
               if(nextCandle.open > nextCandle.close){
                  nextHigh = MathAbs(nextCandle.open + nextCandle.high) / 2;
                  nextLow = MathAbs(nextCandle.close + nextCandle.low) / 2;
                  //nextHigh = MathAbs( nextCandle.high);
                  //nextLow = MathAbs(nextCandle.low);
               }else{
                  nextLow = MathAbs(nextCandle.open + nextCandle.low) / 2;
                  nextHigh = MathAbs(nextCandle.close + nextCandle.high) / 2;
                  //nextLow = MathAbs(nextCandle.low);
                  //nextHigh = MathAbs(nextCandle.high);
               }
               
               //O sinal está subindo
               if(prevHigh <= nextHigh && prevLow <= nextLow){
                  up++;
               }
               
               //O sinal está descendo
               if(prevHigh >= nextHigh && prevLow >= nextLow){
                  down++;
               }
               
               if(prevCandle.high > maxPrice){
                  maxPrice = prevCandle.high;
               }
               
               if(prevCandle.low < minPrice){
                  minPrice = prevCandle.low;
               }
            }
            averagePontuation.max += lastCandle.high;
            averagePontuation.min += lastCandle.low;
            averagePontuation.max = averagePontuation.max / BARS_NUM;
            averagePontuation.min = averagePontuation.min / BARS_NUM;
            
            datetime actualTime = TimeLocal();
            //int medium = barsPrevActualCandle / 2;
            int medium = BARS_NUM / 2;
            double pontuationEstimate = (averagePontuation.max-averagePontuation.min) / _Point;
            
            up = (up > 0 ? up : 0);
            down = (down > 0 ? down : 0);
            //int pontuationEstimate = 0;
            if(up-down >= medium){ 
               if(up == BARS_NUM){
                 hasAllPeriod = true;
               }
               hasAllPeriod = false;
               selectedPrices.last.close = 0;
               if(pontuationEstimate >= PONTUATION_ESTIMATE ){
                  drawVerticalLine(actualTime, "up" + IntegerToString(numBars), clrYellow);
                  updateSelectedPrices(lastCandle, candles[barsPrevActualCandle-1]);
                  waitNewPeriod = true;
                  return UP;
              }
            }else if(down-up >= medium){
               if(down == BARS_NUM){
                 hasAllPeriod = true;
               }
               hasAllPeriod = false;
               selectedPrices.last.close = 0;
               if(pontuationEstimate >= PONTUATION_ESTIMATE){
                  drawVerticalLine(actualTime, "down" + IntegerToString(numBars), clrBlue);
                  updateSelectedPrices(lastCandle, candles[barsPrevActualCandle-1]);
                  waitNewPeriod = true;
                  return DOWN;
               }
            }else{
               return MEDIUM;
            }
         }
      }
      else{
         contador++;
         if(contador >= BARS_NUM){
            //closeBuyOrSell();
            resetPeriodToEntry();
            hasAllPeriod = false;
         }else{
            return closeRiskDeals();
         }
      }
   }else{
      if(activatedBorderRobot == true && hasAllPeriod == false) {
         return decideToBuyOrSellPerTicks();
      }
   }
   
   return MEDIUM;
}

ORIENTATION closeRiskDeals(){
   goToNewCandle = MEDIUM;
   // verifica se existe posicao aberta e qual tipo de tipo de posicao esta ativo
   if(selectedPrices.last.close > 0 ){  //&& PositionSelect(_Symbol) == true
      MqlRates precos[];
      ArraySetAsSeries(precos, true);
      int copiedPrice = CopyRates(_Symbol,_Period,0,1,precos);
      if(copiedPrice == 1 && hasPositionOpen(true)){
         bool up = false;
         double pontuationEstimateMin = (precos[0].low + selectedPrices.last.low + selectedPrices.secondLast.low) / 3;
         double pontuationEstimateMax = (precos[0].high + selectedPrices.last.high + selectedPrices.secondLast.high) / 3;
         double pontuationEstimate = (pontuationEstimateMax-pontuationEstimateMin) / _Point;
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
            //Sinal Subindo
            if((selectedPrices.secondLast.low < selectedPrices.last.low) && 
               (selectedPrices.last.low < precos[0].low || selectedPrices.last.low < precos[0].open)){
                  Print("Ação -> COMPRA. O preço está subindo.");
                  closeBuyOrSell();
                  return DOWN;
            }else{
               Print("Sem a certeza de que o preço está subindo. Encerrando a compra.");
               closeBuyOrSell();
               resetPeriodToEntry();
               updateSelectedPrices(precos[0], selectedPrices.last);
               if(SCALPER == ON){
                  activatedBorderRobot = true;
                  drawBorders(precos[0], pontuationEstimate);
                  return DOWN;
               }
            }
         }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
            //Sinal descendo
            if((selectedPrices.secondLast.high > selectedPrices.last.high) && 
               (selectedPrices.last.high > precos[0].high || selectedPrices.last.high > precos[0].open)){
                  Print("Ação -> VENDA. O preço está descendo.");
                  closeBuyOrSell();
                  return UP;
            }else{
               Print("Sem a certeza de que o preço está descendo. Encerrando a venda.");
               closeBuyOrSell();
               resetPeriodToEntry();
               updateSelectedPrices(precos[0], selectedPrices.last);
               if(SCALPER == ON){
                  activatedBorderRobot = true;
                  drawBorders(precos[0], pontuationEstimate);
                  return UP;
               }
            }
         }
      }
   }
   
   return MEDIUM;
}

void updateSelectedPrices(MqlRates& lastPrice, MqlRates& secLastPrice){
   selectedPrices.secondLast = secLastPrice;
   selectedPrices.last = lastPrice;
}

void resetPeriodToEntry(){
   waitNewPeriod = false;
   contador = -1;
}

void normalizeTakeProfitAndStopLoss(){
   // modificação para o indice dolar DOLAR_INDEX
   if(STOP_LOSS != 0 || TAKE_PROFIT != 0){
      if(_Digits == 3){
         stopLoss = (STOP_LOSS * 1000);
         takeProfit = (TAKE_PROFIT * 1000);  
      }else{
         stopLoss = NormalizeDouble((STOP_LOSS * _Point), _Digits);
         takeProfit = NormalizeDouble((TAKE_PROFIT * _Point), _Digits); 
      }
      
      if(STOP_MOVEL == ON){
         if(hasPositionOpen(true)){
            MqlRates precos[];
            ArraySetAsSeries(precos, true);
            int copiedPrice = CopyRates(_Symbol,_Period,0,1,precos);
            if(copiedPrice == 1){
               double precoEntrada = selectedPrices.secondLast.close;
               double precoAtual = precos[0].close;
               double diff = (precoEntrada - precoAtual);
               
               if(diff > 0){
                  if((diff / _Point) >= (TAKE_PROFIT * percentProfitOrLoss)){
                    stopLoss = NormalizeDouble((STOP_LOSS * percentProfitOrLoss * _Point), _Digits);
                    tradeLib.PositionModify(PositionGetTicket(0),stopLoss,TAKE_PROFIT);
                    Print("Movendo o Stop");
                  }
               }
            }
         }
      }
   }
}

void realizeDeals(TYPE_NEGOCIATION typeDeals, int volume){
   /**/
   if(AGAINST_CURRENT == ON){
      if(typeDeals == BUY){
         typeDeals = SELL;            
      }
      else if(typeDeals == SELL){
         typeDeals = BUY;
      }   
   }
   
   if(typeDeals != NONE){
      
      normalizeTakeProfitAndStopLoss();   
      if(hasPositionOpen(false)) {
         //Instanciar TICKS
         SymbolInfoTick(_Symbol, tick);
         if(typeDeals == BUY){ 
            double stopLossNormalized = NormalizeDouble((tick.ask - stopLoss), _Digits);
            double takeProfitNormalized = NormalizeDouble((tick.ask + takeProfit), _Digits);
            tradeLib.Buy(volume, _Symbol, NormalizeDouble(tick.ask,_Digits), stopLossNormalized, takeProfitNormalized);
         }
         else if(typeDeals == SELL){
            double stopLossNormalized = NormalizeDouble((tick.bid + stopLoss), _Digits);
            double takeProfitNormalized = NormalizeDouble((tick.bid - takeProfit), _Digits);
            tradeLib.Sell(volume, _Symbol, NormalizeDouble(tick.bid,_Digits), stopLossNormalized, takeProfitNormalized);
         }
         
         if(verifyResultTrade()){
            if(CONNECT_AI == ON){
               int copied = CopyRates(_Symbol,_Period,0, 1, candles);
               if(copied == 1){
                  FinishDeal deal = finishedDeals[countFinishedDeals];
                  deal.open = candles[0].open;
                  deal.type = typeDeals;
                  finishedDeals[countFinishedDeals] = deal;
               }
            }
         }
       }else{
         closeBuyOrSell();
       }
    }
 }

void toCloseDeals(){
   dateClosedDeal = TimeLocal();
   closedDeals = true;
}

void startDeals(){
   if(timeToProtection(START_PROTECTION_TIME, MAJOR) && timeToProtection(END_PROTECTION_TIME, MINOR)){
      if(printTimeProtect == true){
         Print("Horario de proteção ativo");
         printTimeProtect = false;
      }
   }else if(timeToProtection(NEGOCIATIONS_LIMIT_TIME, MAJOR) ){
      if(printEndTimeDeal == true){
         Print("Fim do tempo operacional. Encerrando Negociações");
         printEndTimeDeal = false;
      }
      toCloseDeals();
   }else{
      ORIENTATION orient = verifyOrientation();
      decideToBuyOrSellPerCandle(orient);    
      getHistory();
   }
   verifyDayTrade();
}

void drawHorizontalLine(double price, string nameLine, color indColor){
   ObjectCreate(_Symbol,nameLine,OBJ_HLINE,0,0,price);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
   ObjectMove(_Symbol,nameLine,0,0,price);
}

void drawVerticalLine(datetime time, string nameLine, color indColor){
   ObjectCreate(_Symbol,nameLine,OBJ_VLINE,0,time,0);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
}

void createButton(string nameLine, int xx, int yy, int largura, int altura, int canto, int tamanho, string fonte, string text, long corTexto, long corFundo, long corBorda, bool oculto){
   ObjectCreate(_Symbol,nameLine,OBJ_BUTTON,0,0,0);
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

bool hasNewCandle(){
   static datetime lastTime = 0;
   
   datetime lastBarTime = (datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
   
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

void drawBorders(MqlRates& precoAtual, double pontuationEstimate){
   double precoFechamento = precoAtual.close;
   
   if(RANDOM_PONTUATION != AVERAGE_0){
      BordersOperation averagePontuation = calculateAveragePontuation(RANDOM_PONTUATION);
      double averagePointed = ((averagePontuation.max-averagePontuation.min));
      borders.max = MathAbs(averagePointed + precoFechamento);
      borders.min = MathAbs(averagePointed - precoFechamento);
   }else{
      borders.max = MathAbs(_Point * pontuationEstimate + precoFechamento);
      borders.min = MathAbs(_Point * pontuationEstimate - precoFechamento);
   }
   
   drawHorizontalLine(borders.max, "BorderMax", clrRed);
   drawHorizontalLine(borders.min, "BorderMin", clrRed);
   //Print("Atualização de Bordas");
}

void removeDeals(){
   Print("Removendo negociações..");
   Print("Posições em aberto: ", PositionsTotal());
   while(PositionsTotal() > 0){
      Print("Posições em aberto: ", PositionsTotal());
      closeBuyOrSell();
   }
   
   toCloseDeals();
}

BordersOperation calculateAveragePontuation(AVERAGE_PONTUATION averageSelected){
   BordersOperation averagePontuation;
   averagePontuation.max = 0;
   averagePontuation.min = 0;
   int sizeAverages = 0;
   
   if(averageSelected == AVERAGE_10){
      sizeAverages = 10;
   }else if(averageSelected == AVERAGE_5){
      sizeAverages = 5;
   }else if(averageSelected == AVERAGE_15){
      sizeAverages = 15;
   }else if(averageSelected == AVERAGE_20){
      sizeAverages = 20;
   }else if(averageSelected == AVERAGE_25){
      sizeAverages = 25;
   }else if(averageSelected == AVERAGE_30){
      sizeAverages = 30;
   }

   if(sizeAverages != 0){
      MqlRates averages[];
      ArraySetAsSeries(averages, true);
      int copied = CopyRates(_Symbol,_Period,0,sizeAverages, averages);
      if(copied){
         for(int i = 0; i < sizeAverages; i++){
            averagePontuation.max += averages[i].high;
            averagePontuation.min += averages[i].low;
         }
         averagePontuation.max = averagePontuation.max / sizeAverages;
         averagePontuation.min = averagePontuation.min / sizeAverages;
      }
   }
   
   return averagePontuation;
}

ORIENTATION decideToBuyOrSellPerTicks(){
   MqlRates precos[];
   ArraySetAsSeries(precos, true);
   int copiedPrice = CopyRates(_Symbol,_Period,0,1,precos);
   if(copiedPrice == 1){
      double precoAtual = precos[0].close;
      TYPE_NEGOCIATION typeDeal = NONE;
      if(precoAtual >= borders.max){
         //activatedBorderRobot = false;
         if(hasPositionOpen(true)){
            closeBuyOrSell();
            waitNewPeriod = true;
            activatedBorderRobot = false;
         }else{
            return UP;
         }
      }else if(precoAtual <= borders.min){
         if(hasPositionOpen(true)){
            closeBuyOrSell();
            waitNewPeriod = true;
            activatedBorderRobot = false;
         }else{
            return DOWN;
         }
      }
      
      //getHistory();
   }
   
   return MEDIUM;
}

void verifyDayTrade(){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   if(countDays == 1 && timeStarted == 0){
      timeStarted = TimeCurrent();
   }
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(timeStarted, structDate);
   if(structDate.day_of_year != structActual.day_of_year){
      timeStarted = actualTime;
      printEndTimeDeal = true;
      printTimeProtect = true;
      closedDeals = false;
      countDays++; 
      Print("Ganho do dia -> R$", DoubleToString(resultDeals.liquidResult, 2));
      Print("Negociações Encerradas para o dia: ", TimeToString(dateClosedDeal, TIME_DATE));
      Print("Negociações Abertas para o dia: ", TimeToString(actualTime, TIME_DATE));
   }
}

bool hasPositionOpen(bool posBool){
    if(PositionSelect(_Symbol) == posBool) {
      return true;       
    }
    
    return false;
}