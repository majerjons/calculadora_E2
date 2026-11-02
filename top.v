module top (
    //Pines
    //entradas del teclado (su pull-up se configuro en el archivo de constrains)(logica invertida en el barrido!)
    input  wire gpio_2 
    input  wire gpio_46
    input  wire gpio_47
    input  wire gpio_45

    //salidas del teclado para el ringcounter (el recorrido)
    output wire gpio_48
    output wire gpio_3
    output wire gpio_4
    output wire gpio_44

);

    //define el wire del clock, y concateno/incluyo el archivo donde esta el modulo del clock
    //por un tema de prolijidad prefiero hacerlo asi, tipo un main y varios archivos con sus modulos.
    
    wire clk_intern;
    wire clk_externo;
    wire tick_barrido;
    wire tick_anti_rebote;


    //Instancio el modulo del clock y le asigno sus salidas a las variables wire de antes
    //es tipo el include de prototipo de estructuras con sus campos.

    clock u_clock (
        .clk_48mhz(clk_intern)
    );


endmodule