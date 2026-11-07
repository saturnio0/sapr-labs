`timescale 1ns/1ps
// Слейв шины APB с четырьмя 32-битными регистрами (смещения 0x0, 0x4, 0x8, 0xC).
module apb_slave
(
    input  logic        pclk,      // синхросигнал
    input  logic        presetn,   // сброс (активный уровень - 0)
    input  logic [31:0] paddr,     // адрес обращения
    input  logic [31:0] pwdata,    // данные для записи
    input  logic        psel,      // устройство выбрано
    input  logic        penable,   // фаза ACCESS
    input  logic        pwrite,    // 1 - запись, 0 - чтение
    output logic        pready,    // слейв готов
    output logic        pslverr,   // ошибка обращения (неверный адрес)
    output logic [31:0] prdata     // данные чтения
);

    logic [31:0] register_with_some_name; // смещение 0x0: хранит AAAA_AAAA или 5555_5555
    logic [31:0] reg_date;                // смещение 0x4: дата
    logic [31:0] reg_surname;             // смещение 0x8: 4 буквы фамилии (ASCII)
    logic [31:0] reg_name;                // смещение 0xC: 4 буквы имени (ASCII)

    // Состояния конечного автомата (FSM) протокола APB
    enum logic [1:0] {
        APB_SETUP,      // ожидание фазы SETUP от мастера
        APB_W_ENABLE,   // фаза ACCESS записи
        APB_R_ENABLE    // фаза ACCESS чтения
    } apb_st;

    always @(posedge pclk)
    if (!presetn)                                  // синхронный сброс
    begin
        prdata  <= '0;
        pslverr <= 1'b0;
        pready  <= 1'b0;
        register_with_some_name <= 32'h0;
        reg_date <= 32'h0; reg_surname <= 32'h0; reg_name <= 32'h0;
        apb_st  <= APB_SETUP;
    end
    else
    begin
        case (apb_st)
        APB_SETUP:
        begin: apb_setup_st
            prdata  <= '0;                         // очищаем данные,
            pready  <= 1'b0;                       // готовность
            pslverr <= 1'b0;                       // и ошибку от прошлой транзакции
            if (psel && !penable)                  // пришла фаза SETUP
            begin
                if (pwrite == 1'b1) apb_st <= APB_W_ENABLE; // запись
                else                apb_st <= APB_R_ENABLE; // чтение
            end
        end: apb_setup_st

        APB_W_ENABLE:
        begin: apb_w_en_st
            if (psel && penable && pwrite)
            begin
                pready <= 1'b1;                    // сообщаем мастеру, что запись принята
                case (paddr[7:0])                  // декодируем смещение адреса
                8'h0: begin
                    // младший бит данных выбирает значение регистра
                    if (pwdata[0] == 1'b0) register_with_some_name <= 32'hAAAA_AAAA;
                    else                   register_with_some_name <= 32'h5555_5555;
                    $display("[%0d ns] APB SLAVE: WRITE offset=0x0 data=0x%h -> register_with_some_name=0x%h",
                             $time, pwdata, (pwdata[0] ? 32'h5555_5555 : 32'hAAAA_AAAA));
                end
                8'h4: begin
                    reg_date <= pwdata;
                    $display("[%0d ns] APB SLAVE: WRITE offset=0x4 data=0x%h (date)", $time, pwdata);
                end
                8'h8: begin
                    reg_surname <= pwdata;
                    $display("[%0d ns] APB SLAVE: WRITE offset=0x8 data=0x%h (surname '%s')", $time, pwdata, pwdata);
                end
                8'hC: begin
                    reg_name <= pwdata;
                    $display("[%0d ns] APB SLAVE: WRITE offset=0xC data=0x%h (name '%s')", $time, pwdata, pwdata);
                end
                default: begin
                    pslverr <= 1'b1;               // неизвестный адрес - ошибка
                    $display("[%0d ns] APB SLAVE: WRITE ERROR, bad offset 0x%h", $time, paddr[7:0]);
                end
                endcase
                apb_st <= APB_SETUP;               // транзакция окончена
            end
        end: apb_w_en_st

        APB_R_ENABLE:
        begin: apb_r_en_st
            if (psel && penable && !pwrite)
            begin
                pready <= 1'b1;
                case (paddr[7:0])
                8'h0: begin prdata <= register_with_some_name;
                    $display("[%0d ns] APB SLAVE: READ  offset=0x0 data=0x%h", $time, register_with_some_name); end
                8'h4: begin prdata <= reg_date;
                    $display("[%0d ns] APB SLAVE: READ  offset=0x4 data=0x%h", $time, reg_date); end
                8'h8: begin prdata <= reg_surname;
                    $display("[%0d ns] APB SLAVE: READ  offset=0x8 data=0x%h", $time, reg_surname); end
                8'hC: begin prdata <= reg_name;
                    $display("[%0d ns] APB SLAVE: READ  offset=0xC data=0x%h", $time, reg_name); end
                default: begin
                    pslverr <= 1'b1;
                    $display("[%0d ns] APB SLAVE: READ ERROR, bad offset 0x%h", $time, paddr[7:0]);
                end
                endcase
                apb_st <= APB_SETUP;
            end
        end: apb_r_en_st

        default:
        begin
            pslverr <= 1'b1;                       // недостижимое состояние - ошибка
            apb_st  <= APB_SETUP;
        end
        endcase
    end

endmodule
