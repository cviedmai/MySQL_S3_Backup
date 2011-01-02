#!/usr/bin/env ruby

require "common"

begin
  FileUtils.mkdir_p @temp_dir

  # assumes the bucket's empty
  dump_file = "#{@temp_dir}/dump.sql.gz"
  
  cmd = "mysqldump --quick --single-transaction --create-options -u#{@mysql_user}  --flush-logs --master-data=2 --delete-master-logs"
  cmd += " -p'#{@mysql_password}'" unless @mysql_password.nil?
  cmd += " #{@mysql_database} | gzip > #{dump_file}"
  run(cmd)
  
  AWS::S3::S3Object.store(File.basename(dump_file), open(dump_file), @s3_bucket)

  #Deleting old incremental backups (mod by cviedmai)
  files = AWS::S3::Bucket.find(@s3_bucket).objects.dup
  files.each do |f|
    AWS::S3::S3Object.delete(f.key, @s3_bucket) if f.key =~ /mysql-bin.[0-9]*/
  end

ensure
  FileUtils.rm_rf(@temp_dir)
end
