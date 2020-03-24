package main

import (
	"fmt"
	"github.com/tarm/serial"
	"bufio"
	"os"
	"strconv"
	"time"
	"encoding/hex"
	"bytes"
	"encoding/binary"
	"sync"
)

type mt_var struct {
	u32 uint32
	i32 int32
	f32 float32
	choice int64
}

func (v *mt_var) Parse(varvalue_b []byte) {
	reader := bytes.NewReader(varvalue_b)

	switch v.choice {
	case 1:
		if err := binary.Read(reader, binary.BigEndian, &v.u32); err != nil {
			fmt.Println("Error occurred while parsing bytes to uint32: ", err)
		}
	case 2:
		if err := binary.Read(reader, binary.BigEndian, &v.i32); err != nil {
			fmt.Println("Error occurred while parsing bytes to int32: ", err)
		}
	case 3:
		if err := binary.Read(reader, binary.BigEndian, &v.f32); err != nil {
			fmt.Println("Error occurred while parsing bytes to float: ", err)
		}
	}
}

func (v mt_var) String() (ret string) {
	switch v.choice {
	case 1:
		ret = fmt.Sprintf("%v", v.u32)
	case 2:
		ret = fmt.Sprintf("%v", v.i32)
	case 3:
		ret = fmt.Sprintf("%v", v.f32)
	}
	return
}

func main() {
	scanner := bufio.NewScanner(os.Stdin)

	defer func() {
		fmt.Println("Press any key to exit")
		scanner.Scan()
	}()

	fmt.Print("Enter serial port name: ")
	scanner.Scan()
	portname := scanner.Text()

	fmt.Print("Enter baud rate: ")
	scanner.Scan()
	baud_s := scanner.Text()
	baud, err := strconv.ParseInt(baud_s, 10, 64)

	if err != nil {
		fmt.Println("Unable to parse baud rate: ", err)
		return
	}

	fmt.Print("Enter serial port timeout in seconds: ")
	scanner.Scan()
	timeout_s := scanner.Text()
	timeout, err := strconv.ParseInt(timeout_s, 10, 64)

	if err != nil {
		fmt.Println("Unable to parse timeout value: ", err)
		return
	}

	fmt.Print("Select data type of variables (1 - uint32, 2 - int32, 3 - float32): ")
	scanner.Scan()
	dt_var_s := scanner.Text()
	dt_var, err := strconv.ParseInt(dt_var_s, 10, 64)

	if err != nil {
		fmt.Println("Unable to parse choice value for data type: ", err)
		return
	} else if dt_var < 1 || dt_var > 3 {
		fmt.Println("Invalid choice ", dt_var, " for data type selection")
		return
	}

	fmt.Print("Enter number of variables to be read per timestamp: ")
	scanner.Scan()
	num_vars_s := scanner.Text()
	num_vars, err := strconv.ParseInt(num_vars_s, 10, 64)

	if err != nil {
		fmt.Println("Unable to parse num vars value: ", err)
		return
	}

	fmt.Print("Enter number of bytes per variable: ")
	scanner.Scan()
	num_bytes_per_var_s := scanner.Text()
	num_bytes_per_var, err := strconv.ParseInt(num_bytes_per_var_s, 10, 64)

	if err != nil {
		fmt.Println("Unable to parse num bytes per var value: ", err)
		return
	}

	fmt.Print("Enter total number of timestamps: ")
	scanner.Scan()
	num_timestamps_s := scanner.Text()
	num_timestamps, err := strconv.ParseInt(num_timestamps_s, 10, 64)

	if err != nil{
		fmt.Println("Unable to parse num timestamps value: ", err)
		return
	}

	fmt.Print("Enter DAQ sample time: ")
	scanner.Scan()
	sampletime_s := scanner.Text()
	sampletime, err := strconv.ParseInt(sampletime_s, 10, 64)

	if err != nil {
		fmt.Println("Unable to parse sample time value: ", err)
		return
	}

	c := &serial.Config{Name: portname, Baud: int(baud), ReadTimeout: time.Second * time.Duration(timeout)}
	port, err := serial.OpenPort(c)

	if err != nil {
		fmt.Println("Unable to open serial port: ", err)
		return
	}

	defer func() {
		fmt.Println("Closing serial port")
		port.Close()
	}()

	var wg sync.WaitGroup
	var stop_serial_writer = make(chan bool)

	fmt.Println("Press any key to start reading serial port")
	scanner.Scan()

	wg.Add(1)
	go serial_writer(port, stop_serial_writer, &wg)

	fmt.Println("Starting to read port")

	writer_channel := make(chan []byte, 1000)

	wg.Add(1)
	go writer(writer_channel, num_vars, &wg, sampletime, num_bytes_per_var, dt_var)

	bytes_per_timestamp := num_vars * num_bytes_per_var
	var bytecount int

outer:
	for i := int64(1); i <= num_timestamps; i++ {
		buf := make([]byte, bytes_per_timestamp)

		for j := int64(0); j < bytes_per_timestamp; j++ {
			if n, err := port.Read(buf[j:j+1]); err != nil {
				fmt.Println("Error occurred ", err)
				break outer
			} else {
				bytecount += n
				fmt.Printf("Read %d bytes\r", bytecount)
			}
		}

		writer_channel <- buf
	}

	fmt.Println()

	close(writer_channel)
	stop_serial_writer <- true

	fmt.Println("waiting for all goroutines to exit")
	wg.Wait()
}

func writer(channel chan []byte, num_vars int64, wg *sync.WaitGroup, sampletime int64, bytes_per_var int64, dt_var int64) {
	defer func() {
		wg.Done()
	}()

	home_directory, err := os.UserHomeDir()
	if err != nil {
		fmt.Println("Unable to fetch user home directory: ", err)
		return
	}

	time_str := time.Now().Format("2006-01-02-15-04-05")
	filename_raw := fmt.Sprintf("%s%cserial2csv_raw_%s.txt", home_directory, os.PathSeparator, time_str)
	filename_csv := fmt.Sprintf("%s%cserial2csv_%s.csv", home_directory, os.PathSeparator, time_str)

	f_raw, err := os.Create(filename_raw)
	if err != nil {
		fmt.Println("Unable to create file ", filename_raw, ": ", err)
		return
	}
	defer f_raw.Close()

	f_csv, err := os.Create(filename_csv)
	if err != nil {
		fmt.Println("Unable to create file ", filename_csv, ": ", err)
		return
	}
	defer f_csv.Close()

	bytes_written := 0
	var o_sampletime int64


	for data := range channel {
		hexdata := make([]byte, hex.EncodedLen(len(data)))
		hex.Encode(hexdata, data)
		if n, err := f_raw.Write(hexdata); err != nil {
			bytes_written += n
			fmt.Println("Error occurred while writing to file ", filename_raw, ": ", err)
		}

		fmt.Fprintf(f_csv, "%v,", o_sampletime)
		o_sampletime += sampletime

		for varnumber := int64(1); varnumber <= num_vars; varnumber++ {
			var err error
			var n int

			varvalue_b := data[varnumber * bytes_per_var - bytes_per_var:varnumber * bytes_per_var]
			var varvalue = mt_var{choice: dt_var}
			varvalue.Parse(varvalue_b)

			if varnumber == num_vars {
				n, err = fmt.Fprintln(f_csv, varvalue)
			} else {
				n, err = fmt.Fprintf(f_csv, "%v,", varvalue)
			}

			if err != nil {
				fmt.Println("Error while writing to file ", filename_csv, ": ", err)
			} else {
				bytes_written += n
			}
		}
	}

	fmt.Println("Total bytes written to files ", bytes_written)
	fmt.Println("RAW Data: ", filename_raw)
	fmt.Println("CSV Data: ", filename_csv)
}

func serial_writer(port *serial.Port, stop chan bool, wg *sync.WaitGroup) {
	fmt.Println("Starting serial port writer - sending 1 continuously")

	defer wg.Done()

	data := []byte{1}
	zero := []byte{0}

outer_one:
	for {
		select {
		case <-stop:
			fmt.Println("stopping to send 1 on serial")
			break outer_one
		default:
			port.Write(data)
		}
	}

	zero_stop_timer := time.NewTimer(2 * time.Second)

outer_zero:
	for {
		select {
		case <-zero_stop_timer.C:
			fmt.Println("stopping to send 0 on serial")
			break outer_zero
		default:
			port.Write(zero)
		}
	}

	zero_stop_timer.Stop()
}
