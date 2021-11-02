CREATE DEFINER=`root`@`%` TRIGGER `test00` AFTER INSERT ON `barcodegen` FOR EACH ROW begin
	declare i int default 0;
	declare depanBarcode varchar(11);
	declare blkBarcode varchar(11);
	declare noBarcode int;

	set depanBarcode = concat(new.nmpt, new.idcodetr, new.stokyear, '%');
	select n.nobarcode 
	into depanBarcode
	from barcode n 
	where n.nobarcode like depanBarcode 
	order by n.nobarcode desc 
	limit 1;
	if (char_length(depanBarcode) = 5) then
		begin
			set i = 0;
			set depanBarcode = concat(new.nmpt, new.idcodetr, new.stokyear); 
			set blkBarcode = '00000';
			set noBarcode = 0;
		end;
	else
		begin
			set blkBarcode = right(depanBarcode,5);
			set noBarcode = right(depanBarcode,5);
			set depanBarcode = concat(new.nmpt, new.idcodetr, new.stokyear); 
		end;
	end if;

	simple_loop : loop
		set i = i+1;
		set noBarcode = noBarcode + 1;
		set blkBarcode = noBarcode;
		while (char_length(blkBarcode) < 5) do
			set blkBarcode = concat("0", blkBarcode);
		end while;
		insert into barcode (idcodetr, stkyear, nobarcode, gen_date, status, username, idBarcodeGen)
		values (new.idcodetr, new.stokyear, (concat(depanBarcode, blkBarcode)), NOW(), 'C', new.username, new.id);

		if i = new.jml_gen then
			leave simple_loop;
		end if;

	end loop simple_loop;
	if (
		select exists (
			select 1
			from barcodestk b 
			where b.idcodetr = new.idcodetr and b.stkyear = new.stokyear 
			and b.nmpt = new.nmpt
		)
	) then
		update barcodestk 
		set dibuat = dibuat + new.jml_gen, 
		stok_akhir = stok_akhir + new.jml_gen
		where idcodetr = new.idcodetr and stkyear = new.stokyear
		and nmpt = new.nmpt;
	else 
		INSERT INTO sbg.barcodestk (idcodetr, stkyear, dibuat, dipakai, rusak, stok_akhir ,nmpt)
		VALUES(new.idcodetr, new.stokyear, new.jml_gen, 0, 0, new.jml_gen, new.nmpt);
	end if ;
end
