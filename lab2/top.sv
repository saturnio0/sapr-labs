`timescale 1ns/1ps
// Модуль верхнего уровня: соединяет мастера и слейва и запускает тестовую последовательность.
module top;

    parameter [31:0] p_device_offset = 32'h7000_0000; // базовый адрес слейва
    parameter [31:0] GROUP_NUM     = 32'd6;           // номер в списке группы
    parameter [31:0] DATE_DDMMYYYY = 32'h07112026;    // дата дд.мм.гггг как 8 hex-цифр
    parameter [31:0] SURNAME4      = "Demy";          // первые 4 буквы фамилии (ASCII)
    parameter [31:0] NAME4         = "Alex";          // первые 4 буквы имени (ASCII)

    logic        pclk = 1'b0;
    logic        presetn;
    wire         psel, penable, pwrite, pready, pslverr;
    wire  [31:0] paddr, pwdata, prdata;

    integer errors = 0;
    logic [31:0] rd;

    apb_master u_master (.pclk, .psel, .penable, .pwrite, .paddr, .pwdata, .pready, .pslverr, .prdata);
    apb_slave  u_slave  (.pclk, .presetn, .paddr, .pwdata, .psel, .penable, .pwrite, .pready, .pslverr, .prdata);

    always #10 pclk = ~pclk;                           // период 20 нс

    // Чтение и сравнение с ожидаемым значением
    task check(input [31:0] offset, input [31:0] expected);
        u_master.apb_read(p_device_offset + offset, rd);
        if (rd === expected) $display("CHECK OK   offset=0x%h read=0x%h", offset, rd);
        else begin
            $display("CHECK FAIL offset=0x%h read=0x%h expected=0x%h", offset, rd, expected);
            errors = errors + 1;
        end
    endtask

    initial begin
        $dumpfile("wave1.vcd"); $dumpvars(0, top);
        $monitor("%0t psel=%b penable=%b pwrite=%b paddr=%h pwdata=%h pready=%b", $time, psel, penable, pwrite, paddr, pwdata, pready); 
        presetn = 1'b1;
        repeat (5) @(posedge pclk);
        presetn = 1'b0;                                // сброс
        repeat (5) @(posedge pclk);
        presetn = 1'b1;
        repeat (5) @(posedge pclk);

        // Операции из задания 2
        u_master.apb_write(p_device_offset + 32'h0, GROUP_NUM);
        u_master.apb_write(p_device_offset + 32'h4, DATE_DDMMYYYY);
        u_master.apb_write(p_device_offset + 32'h8, SURNAME4);
        u_master.apb_write(p_device_offset + 32'hC, NAME4);

        // Чтение и проверка (регистр 0x0 хранит шаблон по младшему биту записанного числа)
        check(32'h0, GROUP_NUM[0] ? 32'h5555_5555 : 32'hAAAA_AAAA);
        check(32'h4, DATE_DDMMYYYY);
        check(32'h8, SURNAME4);
        check(32'hC, NAME4);

        // Проверка логики из задания 1: бит 0 = 0 -> AAAA_AAAA, бит 0 = 1 -> 5555_5555
        u_master.apb_write(p_device_offset + 32'h0, 32'h0);
        check(32'h0, 32'hAAAA_AAAA);
        u_master.apb_write(p_device_offset + 32'h0, 32'h1);
        check(32'h0, 32'h5555_5555);

        // Обращение по неверному адресу должно дать pslverr
        u_master.apb_write(p_device_offset + 32'h10, 32'h0);
        if (u_master.transfer_error) $display("CHECK OK   bad address -> PSLVERR=1");
        else begin $display("CHECK FAIL bad address, PSLVERR=0"); errors = errors + 1; end

        repeat (10) @(posedge pclk);
        if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED, errors=%0d", errors);
        $finish;
    end
endmodule
