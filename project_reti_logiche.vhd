----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/22/2023 02:01:27 PM
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity project_reti_logiche is
    port(
        i_clk   : in std_logic;
        i_rst   : in std_logic;
        i_start : in std_logic;
        i_w		: in std_logic;

        o_z0    : out std_logic_vector(7 downto 0);
        o_z1    : out std_logic_vector(7 downto 0);
        o_z2    : out std_logic_vector(7 downto 0);
        o_z3    : out std_logic_vector(7 downto 0);
        o_done  : out std_logic;

        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in std_logic_vector(7 downto 0);
        o_mem_we   : out std_logic;
        o_mem_en   : out std_logic
	);
end project_reti_logiche;

architecture behavioral of project_reti_logiche is
    --FSM and signals
    type state_type is (idle, reset, read_input, check_addr, get_mess, write_mess, ending);
    signal current_state, next_state	:	state_type;
    signal heading_bit					:	std_logic_vector(1 downto 0);
    signal heading_counter				: 	integer range 0 to 2;
    signal address						:	std_logic_vector(15 downto 0);
    signal int_mem_addr					:	std_logic_vector(15 downto 0);
    signal address_counter				:	integer range 0 to 15;
    signal save_data					:	std_logic_vector(7 downto 0);
    signal tmp_z0						:	std_logic_vector(7 downto 0);
    signal tmp_z1						:	std_logic_vector(7 downto 0);
    signal tmp_z2						:	std_logic_vector(7 downto 0);
    signal tmp_z3						:	std_logic_vector(7 downto 0);
    --
begin process(i_clk, i_rst)

        begin
            if(i_rst = '1') then
                current_state   <=  reset;
            elsif(i_clk'event and i_clk = '1') then
            	current_state	<=	next_state;
            end if;
        end process;
        
        -- Values that are going to trigger the FSM to change its state
        process(current_state, i_start, i_w, heading_bit, heading_counter, address, address_counter, i_clk)
        
		--FSM
        begin
	
        	case current_state is
        	
				when reset =>
				
				    tmp_z0		<=  "00000000";
					tmp_z1    	<=  "00000000";
					tmp_z2    	<=  "00000000";
					tmp_z3    	<=  "00000000";
					o_done  	<=  '0';	
					o_mem_en 	<=  '0';
					o_mem_we	<=  '0';	
					o_mem_addr 	<=  "0000000000000000";
					address		<=	"0000000000000000";			
					heading_bit 	<=  "00";
					heading_counter <=  0;
					address_counter <=  0;

					next_state <= idle;
					
				when idle =>
				
					o_mem_en 		<=  '0';
					o_mem_we		<=  '0';	
					address			<=	"0000000000000000";
					address_counter <=  0;
					o_done			<= 	'0';
					o_z0			<=  "00000000";
					o_z1    		<=  "00000000";
					o_z2    		<=  "00000000";
					o_z3    		<=  "00000000";
				
					if(i_clk'event and i_clk = '1' and i_start = '1') then
						
						if(i_clk'event and i_clk = '1' and i_w = '1') then
							if(heading_bit = "00") then
								heading_bit <= "01";
							elsif(heading_bit = "01") then
								heading_bit <= "11";
							elsif(heading_bit = "10") then
								heading_bit <= "01";
							elsif(heading_bit = "11") then
								heading_bit <= "11";
							end if;
						elsif(i_clk'event and i_clk = '1' and i_w = '0') then
							if(heading_bit = "00") then
								heading_bit <= "00";
							elsif(heading_bit = "01") then
								heading_bit <= "10";
							elsif(heading_bit = "10") then
								heading_bit <= "00";
							elsif(heading_bit = "11") then
								heading_bit <= "10";
							end if;
						end if;
						
						heading_counter <= heading_counter + 1;
						next_state <= read_input;
							
					end if;
				
				when read_input =>

					if(i_clk'event and i_clk = '1' and i_start = '1') then
							
						if(heading_counter >= 2) then
					
							if(i_w = '1' and address_counter < 16) then
							
								if(address_counter = 0) then
									address <= "0000000000000001";
								else
									address <= address(14 downto 0) & std_logic_vector(to_unsigned(1, 1));
								end if;
								
							elsif(i_w = '0' and address_counter < 16) then
							
								if(address_counter = 0) then
									address <= "0000000000000000";
								else
									address <= address(14 downto 0) & std_logic_vector(to_unsigned(0, 1));
								end if;
								
							end if;
							
							address_counter <= address_counter + 1;
							next_state <= read_input;
						
						end if;
						
					elsif (i_start = '0') then
						
						heading_counter	<=  0;
						int_mem_addr <= address;	
						next_state <= check_addr;
						
					end if;
					
				when check_addr =>
				
					o_mem_en <= '1';
					o_mem_we <= '0';
					o_mem_addr <= int_mem_addr;
					next_state <= get_mess;
			
				when get_mess =>
				
					o_mem_en <= '1';
					o_mem_we <= '0';
					save_data <= i_mem_data(7 downto 0);	--Saving the RAM message to a tmp signal
					next_state <= write_mess;
				
				when write_mess =>
					o_mem_we <= '0';
					o_mem_en <= '1';
					
					if(heading_bit = "00") then
						tmp_z0 <= save_data;
					elsif(heading_bit = "01") then
						tmp_z1 <= save_data;
					elsif(heading_bit = "10") then
						tmp_z2 <= save_data;
					elsif(heading_bit = "11") then
						tmp_z3 <= save_data;
					end if;
					
					next_state <= ending;
					
					
				when ending =>
								
					o_done <= '1';
					heading_bit <= "00";
			
					o_z0 <= tmp_z0;
					o_z1 <= tmp_z1;
					o_z2 <= tmp_z2;
					o_z3 <= tmp_z3;			
					
					next_state <= idle;
			
			end case;
			
    end process; 
          
end behavioral;