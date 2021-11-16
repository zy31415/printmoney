import base64

from google.cloud import storage

def upload_blob(bucket_name, source_file_name, destination_blob_name):
    """Uploads a file to the bucket."""
    
    # The name of your GCS bucket
    # bucket_name = "your-bucket-name"
    
    # The path and the file to upload
    # source_file_name = "local/path/to/file"
    
    # The name of the file in GCS bucket once uploaded
    # destination_blob_name = "storage-object-name"

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)

    blob.upload_from_filename(source_file_name)

from datetime import datetime


def create_file_name():
    '''Generate a .txt filename using the current timestamp'''
    
    # Convert the current datetime to string
    date = datetime.now().strftime("%Y_%m_%d-%H_%M_%S_%P")

    file_name = 'money_' + date + '.txt'
    
    return file_name



def write_to_file(file_name):
    '''Creates a text file with the text money in it. '''

    
    # Note that in the cloud function environment,
    # we can only write to the /tmp directory. 
    # Hence, we are appending the tmp directory to the file name.

    file_name = '/tmp/' + file_name

    
    with open(file_name, 'w') as f:
        f.write('money')
    
    f.close()
  

def main(event, context):
    """Triggered from a message on a Cloud Pub/Sub topic.
    Args:
         event (dict): Event payload.
         context (google.cloud.functions.Context): Metadata for the event.
    """
    # Create a filename
    file_name = create_file_name()

    print("File name generated: " + file_name)

    # Write the text 'money' and save the file locally
    write_to_file(file_name)

    # Upload the file to GCS bucket
    bucket_name = 'print-money'
    local_file_location = '/tmp/' + file_name
    upload_blob(bucket_name, local_file_location, file_name)
    
