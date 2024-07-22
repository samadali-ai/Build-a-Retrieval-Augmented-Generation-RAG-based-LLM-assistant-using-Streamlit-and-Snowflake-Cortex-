# README - RAG Chat Assistant Application

## Overview

To reduce hallucinations (i.e., incorrect responses), Large Language Models (LLMs) can be combined with private datasets. One effective approach for this is the Retrieval Augmented Generation (RAG) framework, which provides relevant documents as context to the LLM to ground its responses. This quickstart guide demonstrates how to build a full-stack RAG application in Snowflake, ensuring data security within the Snowflake governance framework.

We'll create a chat assistant specialized in smart devices by giving it access to relevant User Manuals. This template can be adapted for other types of documents, such as financial reports or research papers. The guide includes tips for turning a prototype into a production pipeline and highlights relevant Snowflake functionalities for enhancements.

## What You Will Build

The final product includes an application that lets users test LLM responses with and without context documents to show how RAG can address hallucinations.

## What You Will Learn

- How to create functions using Python libraries with Snowpark
- How to generate embeddings, run semantic search, and use LLMs with serverless functions in Snowflake Cortex
- How to build a front-end with Python using Streamlit in Snowflake
- Optional: How to automate data processing pipelines using directory tables, Streams, and Tasks

## Prerequisites

- Snowflake account in a cloud region where Snowflake Cortex LLM functions are supported
- Anaconda Packages enabled by ORGADMIN in your Snowflake account
- Snowflake Cortex vector functions for semantic distance calculations and VECTOR as a data type enabled

## Steps to Build the Application

### 1. Organize Documents and Create Pre-Processing Functions

In Snowflake, databases and schemas are used to organize and govern access to data and logic. Follow these steps:

- Download the necessary documents (e.g., User Manuals) locally.
- Create a database to hold the PDFs, processing functions (for extracting and chunking PDFs), and a table to store text embeddings.

### 2. Build the Vector Store

Leverage the document processing functions to prepare documents and convert the text into embeddings using Snowflake Cortex. Store these embeddings in a Snowflake Table using the VECTOR data type.

### 3. Build Chat UI and Chat (Retrieval and Generation) Logic

Create a simple front-end using Streamlit to allow users to ask questions against the vector store. Include a toggle to test LLM responses with and without context to observe the differences. Streamlit in Snowflake ensures data remains secure and is only available to users meeting role-based access policies.

### 4. Build a ChatBot UI that Remembers Previous Conversations

Enhance the chat interface to support conversation style interactions:

- Use Streamlit's Chat Elements to create a conversation interface.
- Implement a sliding window concept to remember a number of past interactions.
- Summarize previous conversations to find relevant document chunks for context.
- Embed the new question along with the previous summary to provide the right context to the LLM.

## Additional Notes

- Large Language Models (LLMs) are stateless, meaning each call is independent. To maintain conversation flow, the app must keep a memory of the conversation and provide it in each call to the LLM.
- The context window length restricts calls to LLMs. Use a sliding window and summarization techniques to manage this limitation.

## Conclusion

By following this guide, you will build a RAG chat assistant application in Snowflake, leveraging Snowflake Cortex and Streamlit. This setup ensures secure, context-aware interactions with LLMs, reducing hallucinations and improving the reliability of responses.
