#Step 1. Download example documents
#Step 2. Open a new Worksheet
#Relevant documentation: Creating Snowflake Worksheets.
#Step 3. Create a database, schema and a warehouse

CREATE DATABASE CC_QUICKSTART_CORTEX_DOCS;
CREATE SCHEMA DATA;

USE CC_QUICKSTART_CORTEX_DOCS.DATA;

CREATE OR REPLACE WAREHOUSE XS_WH WAREHOUSE_SIZE = XSMALL;
USE WAREHOUSE XS_WH;

#Step 4. Create a table function that will read the PDF documents and split them in chunks
#We will be using the PyPDF2 and Langchain Python libraries to accomplish the necessary document processing tasks.
#Because as part of Snowpark Python these are available inside the integrated Anaconda repository,
#there are no manual installs or Python environment and dependency management required.#

create or replace function pdf_text_chunker(file_url string)
returns table (chunk varchar)
language python
runtime_version = '3.9'
handler = 'pdf_text_chunker'
packages = ('snowflake-snowpark-python','PyPDF2', 'langchain')
as
$$
from snowflake.snowpark.types import StringType, StructField, StructType
from langchain.text_splitter import RecursiveCharacterTextSplitter
from snowflake.snowpark.files import SnowflakeFile
import PyPDF2, io
import logging
import pandas as pd

class pdf_text_chunker:

    def read_pdf(self, file_url: str) -> str:
    
        logger = logging.getLogger("udf_logger")
        logger.info(f"Opening file {file_url}")
    
        with SnowflakeFile.open(file_url, 'rb') as f:
            buffer = io.BytesIO(f.readall())
            
        reader = PyPDF2.PdfReader(buffer)   
        text = ""
        for page in reader.pages:
            try:
                text += page.extract_text().replace('\n', ' ').replace('\0', ' ')
            except:
                text = "Unable to Extract"
                logger.warn(f"Unable to extract from file {file_url}, page {page}")
        
        return text

    def process(self,file_url: str):

        text = self.read_pdf(file_url)
        
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size = 4000, #Adjust this as you see fit
            chunk_overlap  = 400, #This let's text have some form of overlap. Useful for keeping chunks contextual
            length_function = len
        )
    
        chunks = text_splitter.split_text(text)
        df = pd.DataFrame(chunks, columns=['chunks'])
        
        yield from df.itertuples(index=False, name=None)
$$;


#Step 5. Create a Stage with Directory Table where you will be uploading your documents

create or replace stage docs ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE') DIRECTORY = ( ENABLE = true );
#Step 6. Upload documents to your staging area

#Select Data on the left of Snowsight
#Click on your database CC_QUICKSTART_CORTEX_DOCS
#Click on your schema DATA
#Click on Stages and select DOCS
#On the top right click on the +Files botton
#Drag and drop the two PDF files you downloaded

#Step 7. Check files has been successfully uploaded
ls @docs;
#3. Build the Vector Store

#Step 1. Create the table where we are going to store the chunks and vectors for each PDF. Note here the usage of the new VECTOR data type:

create or replace TABLE DOCS_CHUNKS_TABLE ( 
    RELATIVE_PATH VARCHAR(16777216), -- Relative path to the PDF file
    SIZE NUMBER(38,0), -- Size of the PDF
    FILE_URL VARCHAR(16777216), -- URL for the PDF
    SCOPED_FILE_URL VARCHAR(16777216), -- Scoped url (you can choose which one to keep depending on your use case)
    CHUNK VARCHAR(16777216), -- Piece of text
    CHUNK_VEC VECTOR(FLOAT, 768) );  -- Embedding using the VECTOR data type
#Step 2. Use the function previously created to process the PDF files, extract the chunks and created the embeddings.
#Insert that info in the table we have just created:
insert into docs_chunks_table (relative_path, size, file_url,
                            scoped_file_url, chunk, chunk_vec)
    select relative_path, 
            size,
            file_url, 
            build_scoped_file_url(@docs, relative_path) as scoped_file_url,
            func.chunk as chunk,
            SNOWFLAKE.CORTEX.EMBED_TEXT_768('e5-base-v2',chunk) as chunk_vec
    from 
        directory(@docs),
        TABLE(pdf_text_chunker(build_scoped_file_url(@docs, relative_path))) as func;
