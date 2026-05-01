# Keyed File Reader  

Get all records from keyed file.  

## Compilation  

The application is designed to run on IBM 4680 compatible systems.  

Compile the application with the IBM 4680 Basic Compiler.  

```shell
BASIC KFILE.BAS
```  

Link the .obj file with the linker LINK86 Linkage Editor.  
```shell
LINK86 KFILE.OBJ
```

## Execution  

In order to use this application correctly you should know what data types are used for each field and their order in the record. In the next example the first four bytes of the records are packed decimals and the subsequent 20 bytes are characters.

E.g.,

```shell
KFILE P4 C20 INVNTRS.DAT
```
  
This example decodes the first four bytes from packed decimal and prints the data as string characters, also prints the subsequent twenty bytes as string characters. By default the returned fields are separated by commas.  

Result:  
```
00000001,ALEXANDER GRAHAM
00000002,NIKOLA TESLA
00000003,THOMAS EDISON
```  

If run without specifying any field data type the application will return all the records from the file as they are stored, without any data type conversion.  

## Field data types  

c &emsp;- Char  
i &emsp;- Integer  
p &emsp;- Packed Decimal  
e &emsp;- Exclude  


Use ( e ) to ensure certain parts of the record are ignored.

E.g.,

```shell
KFILE E4 C20 INVNTRS.DAT
```
Result:  
```
ALEXANDER GRAHAM
NIKOLA TESLA
THOMAS EDISON
```  

---

<div align="center">
  Readme under construction 👨🏽‍💻..
</div>