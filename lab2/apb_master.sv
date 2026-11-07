`timescale 1ns/1ps
// Мастер шины APB: формирует сигналы шины и содержит задачи (task) записи и чтения.
module apb_master
(
    input  logic        pclk,      // синхросигнал шины
    output logic        psel,      // выбор устройства (фаза SETUP начинается с psel=1)
    output logic        penable,   // признак фазы ACCESS (активная транзакция)
    output logic        pwrite,    // 1 - запись, 0 - чтение
    output logic [31:0] paddr,     // адрес обращения
    output logic [31:0] pwdata,    // данные для записи
    input  logic        pready,    // готовность от слейва
    input  logic        pslverr,   // ошибка от слейва
    input  logic [31:0] prdata     // данные чтения от слейва
);

    logic transfer_error;          // здесь запоминается pslverr последней транзакции

    // Начальные значения: шина в состоянии покоя (нет обращений)
    initial begin
        psel = 1'b0; penable = 1'b0; pwrite = 1'b0;
        paddr = '0;  pwdata = '0;    transfer_error = 1'b0;
    end

    // Запись: SETUP (psel=1, penable=0) -> ACCESS (penable=1) -> ожидание pready -> конец
    task apb_write(input [31:0] addr, input [31:0] data);
        wait ((penable == 0) && (pready == 0)); // ждём, пока предыдущая транзакция закончится
        @(posedge pclk);
        psel   <= 1'b1;                         // фаза SETUP: выбираем слейва,
        paddr  <= addr;                         // выставляем адрес,
        pwdata <= data;                         // данные
        pwrite <= 1'b1;                         // и признак записи
        @(posedge pclk);
        penable <= 1'b1;                        // фаза ACCESS: транзакция активна
        @(posedge pclk);
        wait (pready == 1'b1);                  // ждём подтверждения от слейва
        transfer_error = pslverr;               // запоминаем признак ошибки
        @(posedge pclk);
        psel <= 1'b0; penable <= 1'b0; pwrite <= 1'b0; // освобождаем шину
        @(posedge pclk);
    endtask

    // Чтение: то же, но pwrite=0, а данные забираются из prdata
    task apb_read(input [31:0] addr, output logic [31:0] data);
        wait ((penable == 0) && (pready == 0));
        @(posedge pclk);
        psel   <= 1'b1;
        pwrite <= 1'b0;
        paddr  <= addr;
        @(posedge pclk);
        penable <= 1'b1;
        @(posedge pclk);
        wait (pready == 1'b1);
        transfer_error = pslverr;
        @(posedge pclk);
        data = prdata;                          // данные от слейва действительны вместе с pready
        psel <= 1'b0; penable <= 1'b0;
        @(posedge pclk);
    endtask

endmodule
