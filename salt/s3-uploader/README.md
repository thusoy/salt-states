s3-uploader
===========

Allows easy uploading of files to S3. Does not support the new AWS4 signatures
yet, thus if you get the error "The authorization mechanism you have provided
is not supported. Please use AWS4-HMAC-SHA256." you need to either implement
this or use awscli/mc/s3cmd or any other tool to perform the upload that
supports this.
