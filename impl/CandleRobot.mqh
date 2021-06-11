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


input POWER TESTING_DAY = ON;
input POWER AGAINST_CURRENT = ON;
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
int countDays = 0;
bool advanceDeal = false;
datetime avaliationTime;
bool periodAchieved = false;
InfoDeal infoDeal;
bool activeDeal = false;
bool startedAvaliationTime = false;
SelectedPrices selectedPrices;
datetime dateClosedDeal;
bool closedDeals = false;
bool isPossivelToSell = false;
int maxPositionsArray = 2;
BordersOperation borders;
bool waitNewPeriod = false;
double profits = 0;
double losses = 0;

int printTimeProtect = true;
int printEndTimeDeal = true;
ResultOperation resultDeals;

void startRobots(){
  printf("Start Robots in " +  _Symbol);
  //CopyRates(_Symbol,_Period,0,maxPositionsArray,candles);
  //ArraySetAsSeries(candles, true);
  Print("Negociações Abertas para o dia: ", TimeToString(TimeCurrent(), TIME_DATE));
  createButton("BotaoPanic", WIDTH_BUTTON_PANIC, HEGHT_BUTTON_PANIC, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Negociacoes", clrWhite, clrRed, clrRed, false);
}

void finishRobots(){
  printf("Finish Robots in " +  _Symbol);
}

void closeBuyOrSell(){
   ulong ticket = PositionGetTicket(0);
   tradeLib.PositionClose(ticket);
   verifyResultTrade();
}

void decideToBuyOrSell(ORIENTATION orient){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   /**/
   if(AGAINST_CURRENT == ON){
      if(typeDeal == BUY){
         typeDeal = SELL;            
      }
      else if(typeDeal == SELL){
         typeDeal = BUY;
      }   
   }
   
   realizeDeals(typeDeal);
   getHistory();
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
            double prevHigh = 0, prevLow = 0, nextHigh = 0, nextLow = 0;
            BordersOperation averagePontuation;
            averagePontuation.max = 0;
            averagePontuation.min = 0;
            
            for(int i = 0; i < barsPrevActualCandle; i++){
               prevCandle = candles[i];
               nextCandle = candles[i+1];
               averagePontuation.max += prevCandle.high;
               averagePontuation.min += prevCandle.low;
               
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
               }else{
                  nextLow = MathAbs(nextCandle.open + nextCandle.low) / 2;
                  nextHigh = MathAbs(nextCandle.close + nextCandle.high) / 2;
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
            int medium = barsPrevActualCandle / 2;
            double pontuationEstimate = (averagePontuation.max-averagePontuation.min) / _Point;
            //int pontuationEstimate = 0;
            if(up > medium){ 
               //pontuationEstimate = (lastCandle.high - candles[0].low) / _Point;
               selectedPrices.last.close = 0;
               if(pontuationEstimate >= PONTUATION_ESTIMATE ){
                  drawVerticalLine(actualTime, "up" + IntegerToString(numBars), clrYellow);
                  selectedPrices.last = lastCandle;
                  selectedPrices.secondLast = candles[barsPrevActualCandle-1];
                  waitNewPeriod = true;
                  return UP;
              }
            }else if(down > medium){
              // pontuationEstimate = (candles[0].high - lastCandle.low) / _Point;
               selectedPrices.last.close = 0;
               if(pontuationEstimate >= PONTUATION_ESTIMATE){
                  drawVerticalLine(actualTime, "down" + IntegerToString(numBars), clrBlue);
                  selectedPrices.last = lastCandle;
                  selectedPrices.secondLast = candles[barsPrevActualCandle-1];
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
            closeBuyOrSell();
            resetPeriodToEntry();
         }else{
            closeRiskDeals();
         }
      }
   }else{
      if(waitNewPeriod == true) {
        // closeRiskDeals();
      }
   }
   
   return MEDIUM;
}

ORIENTATION closeRiskDeals(){
    /**/
   // verifica se existe posicao aberta e qual tipo de tipo de posicao esta ativo
   if(selectedPrices.last.close > 0 ){  //&& PositionSelect(_Symbol) == true
      MqlRates precos[1];
      int copiedPrice = CopyRates(_Symbol,_Period,0,1,precos);
      if(copiedPrice == 1){
         bool up = false;
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
            //Sinal Subindo
            if((selectedPrices.secondLast.low < selectedPrices.last.low) && 
               (selectedPrices.last.low < precos[0].low || selectedPrices.last.low < precos[0].open)){
                  Print("O preço está subindo. Continuando a compra.");
            }else{
               Print("Sem a certeza de que o preço está subindo. Encerrando a compra.");
               closeBuyOrSell();
               resetPeriodToEntry();
               return DOWN;
            }
         }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
            //Sinal descendo
            if((selectedPrices.secondLast.high > selectedPrices.last.high) && 
               (selectedPrices.last.high > precos[0].high || selectedPrices.last.high > precos[0].open)){
                  Print("O preço está descendo. Continuando a venda.");
            }else{
               Print("Sem a certeza de que o preço está descendo. Encerrando a venda.");
               closeBuyOrSell();
               resetPeriodToEntry();
               return UP;
            }
         }
      }
   }
   return MEDIUM;
}

void resetPeriodToEntry(){
   waitNewPeriod = false;
   contador = 0;
}

void toBuy(){
   double stopLossNormalized = NormalizeDouble((tick.ask - stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.ask + takeProfit), _Digits);
   tradeLib.Buy(ACTIVE_VOLUME, _Symbol, NormalizeDouble(tick.ask,_Digits), stopLossNormalized, takeProfitNormalized);
}

void toSell(){
   double stopLossNormalized = NormalizeDouble((tick.bid + stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.bid - takeProfit), _Digits);
   tradeLib.Sell(ACTIVE_VOLUME, _Symbol, NormalizeDouble(tick.bid,_Digits), stopLossNormalized, takeProfitNormalized);
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
   }
}

void realizeDeals(TYPE_NEGOCIATION typeDeals){
   if(typeDeals != NONE){
      normalizeTakeProfitAndStopLoss();   
      if(PositionSelect(_Symbol) == false) {
         //Instanciar TICKS
         SymbolInfoTick(_Symbol, tick);
         if(typeDeals == BUY){
            toBuy();
         }
         else if(typeDeals == SELL){
            toSell();
         }
         
         if(verifyResultTrade()){
            //Salvar informacoes da negociação iniciado
            infoDeal.price = PositionGetDouble(POSITION_PRICE_CURRENT);
            infoDeal.ticket = PositionGetTicket(0);
            infoDeal.timeStartDeal = TimeLocal();
         }
       }
    }
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
   " Number of days: " + IntegerToString(countDays, 2));
   
   resultDeals.losses = resultOperation.losses;
   resultDeals.profits = resultOperation.profits;
   resultDeals.profitFactor = resultOperation.profitFactor;
   resultDeals.liquidResult = resultOperation.liquidResult;
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
      decideToBuyOrSell(orient);    
   }
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

void removeDeals(){
   Print("Removendo negociações..");
   Print("Posições em aberto: ", PositionsTotal());
   while(PositionsTotal() > 0){
      Print("Posições em aberto: ", PositionsTotal());
      closeBuyOrSell();
   }
   
   toCloseDeals();
}
