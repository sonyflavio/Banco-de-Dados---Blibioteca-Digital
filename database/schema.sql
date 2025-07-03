-- ===============================================
-- SISTEMA DE BIBLIOTECA DIGITAL
-- Projeto de Banco de Dados
-- Autor: Flavio Serra
-- Data: Julho 2025
-- SGBD: PostgreSQL
-- ===============================================

-- Criação do banco de dados
CREATE DATABASE biblioteca_digital;

-- Conectar ao banco de dados
\c biblioteca_digital;


-- CRIAÇÃO DAS TABELAS


-- Tabela de usuários
CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    tipo_usuario VARCHAR(20) CHECK (tipo_usuario IN ('estudante', 'professor', 'funcionario')),
    data_cadastro DATE DEFAULT CURRENT_DATE,
    status BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de categorias
CREATE TABLE categoria (
    id_categoria SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    descricao TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de autores
CREATE TABLE autor (
    id_autor SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    nacionalidade VARCHAR(50),
    data_nascimento DATE,
    biografia TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de itens (livros, artigos, etc.)
CREATE TABLE item (
    id_item SERIAL PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    subtitulo VARCHAR(200),
    tipo_item VARCHAR(20) CHECK (tipo_item IN ('livro', 'artigo', 'revista', 'tese', 'dissertacao')),
    isbn VARCHAR(20),
    issn VARCHAR(20),
    data_publicacao DATE,
    editora VARCHAR(100),
    edicao VARCHAR(20),
    paginas INTEGER,
    idioma VARCHAR(30) DEFAULT 'Português',
    disponivel BOOLEAN DEFAULT TRUE,
    localizacao VARCHAR(50),
    observacoes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de relacionamento item-autor (N:M)
CREATE TABLE item_autor (
    id_item INTEGER REFERENCES item(id_item) ON DELETE CASCADE,
    id_autor INTEGER REFERENCES autor(id_autor) ON DELETE CASCADE,
    tipo_contribuicao VARCHAR(20) DEFAULT 'autor' CHECK (tipo_contribuicao IN ('autor', 'organizador', 'tradutor', 'ilustrador')),
    PRIMARY KEY (id_item, id_autor)
);

-- Tabela de relacionamento item-categoria (N:M)
CREATE TABLE item_categoria (
    id_item INTEGER REFERENCES item(id_item) ON DELETE CASCADE,
    id_categoria INTEGER REFERENCES categoria(id_categoria) ON DELETE CASCADE,
    PRIMARY KEY (id_item, id_categoria)
);

-- Tabela de empréstimos
CREATE TABLE emprestimo (
    id_emprestimo SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuario(id_usuario),
    id_item INTEGER NOT NULL REFERENCES item(id_item),
    data_emprestimo DATE DEFAULT CURRENT_DATE,
    data_devolucao_prevista DATE NOT NULL,
    data_devolucao_real DATE,
    status VARCHAR(20) DEFAULT 'ativo' CHECK (status IN ('ativo', 'devolvido', 'atrasado', 'renovado')),
    renovacoes INTEGER DEFAULT 0,
    multa_valor DECIMAL(10,2) DEFAULT 0.00,
    observacoes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de reservas
CREATE TABLE reserva (
    id_reserva SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuario(id_usuario),
    id_item INTEGER NOT NULL REFERENCES item(id_item),
    data_reserva DATE DEFAULT CURRENT_DATE,
    data_expiracao DATE,
    status VARCHAR(20) DEFAULT 'ativa' CHECK (status IN ('ativa', 'cancelada', 'atendida', 'expirada')),
    observacoes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de histórico de ações (auditoria)
CREATE TABLE historico_acoes (
    id_historico SERIAL PRIMARY KEY,
    tabela_afetada VARCHAR(50) NOT NULL,
    id_registro INTEGER NOT NULL,
    acao VARCHAR(20) NOT NULL CHECK (acao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_anteriores JSONB,
    dados_novos JSONB,
    usuario_sistema VARCHAR(50),
    ip_address INET,
    data_acao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- CRIAÇÃO DE ÍNDICES


-- Índices para otimização de consultas
CREATE INDEX idx_usuario_email ON usuario(email);
CREATE INDEX idx_usuario_tipo ON usuario(tipo_usuario);
CREATE INDEX idx_item_titulo ON item(titulo);
CREATE INDEX idx_item_tipo ON item(tipo_item);
CREATE INDEX idx_item_isbn ON item(isbn);
CREATE INDEX idx_item_disponivel ON item(disponivel);
CREATE INDEX idx_emprestimo_usuario ON emprestimo(id_usuario);
CREATE INDEX idx_emprestimo_item ON emprestimo(id_item);
CREATE INDEX idx_emprestimo_status ON emprestimo(status);
CREATE INDEX idx_emprestimo_data ON emprestimo(data_emprestimo);
CREATE INDEX idx_reserva_usuario ON reserva(id_usuario);
CREATE INDEX idx_reserva_item ON reserva(id_item);
CREATE INDEX idx_reserva_status ON reserva(status);
CREATE INDEX idx_autor_nome ON autor(nome);
CREATE INDEX idx_categoria_nome ON categoria(nome);


-- CRIAÇÃO DE TRIGGERS


-- Função para atualizar campo updated_at
CREATE OR REPLACE FUNCTION atualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para atualizar timestamp automaticamente
CREATE TRIGGER trigger_usuario_updated_at
    BEFORE UPDATE ON usuario
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

CREATE TRIGGER trigger_item_updated_at
    BEFORE UPDATE ON item
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

CREATE TRIGGER trigger_emprestimo_updated_at
    BEFORE UPDATE ON emprestimo
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

CREATE TRIGGER trigger_reserva_updated_at
    BEFORE UPDATE ON reserva
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar disponibilidade do item
CREATE OR REPLACE FUNCTION atualizar_disponibilidade_item()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status = 'ativo' THEN
        UPDATE item SET disponivel = FALSE WHERE id_item = NEW.id_item;
    ELSIF TG_OP = 'UPDATE' AND OLD.status = 'ativo' AND NEW.status = 'devolvido' THEN
        UPDATE item SET disponivel = TRUE WHERE id_item = NEW.id_item;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_disponibilidade_item
    AFTER INSERT OR UPDATE ON emprestimo
    FOR EACH ROW EXECUTE FUNCTION atualizar_disponibilidade_item();


-- INSERÇÃO DE DADOS DE TESTE


-- Inserir categorias
INSERT INTO categoria (nome, descricao) VALUES
('Tecnologia', 'Livros sobre tecnologia, programação e ciência da computação'),
('Literatura', 'Obras literárias clássicas e contemporâneas'),
('Ciências', 'Livros científicos e acadêmicos'),
('História', 'Livros de história geral e específica'),
('Filosofia', 'Obras filosóficas e pensamento crítico'),
('Matemática', 'Livros de matemática pura e aplicada'),
('Educação', 'Livros sobre pedagogia e educação'),
('Arte', 'Livros sobre artes visuais, música e teatro');

-- Inserir autores
INSERT INTO autor (nome, nacionalidade, data_nascimento, biografia) VALUES
('Machado de Assis', 'Brasileira', '1839-06-21', 'Maior escritor brasileiro do século XIX'),
('Donald Knuth', 'Americana', '1938-01-10', 'Cientista da computação, criador do TeX'),
('J.K. Rowling', 'Britânica', '1965-07-31', 'Autora da série Harry Potter'),
('Clarice Lispector', 'Brasileira', '1920-12-10', 'Escritora brasileira renomada'),
('Alan Turing', 'Britânica', '1912-06-23', 'Matemático e cientista da computação'),
('Ada Lovelace', 'Britânica', '1815-12-10', 'Primeira programadora da história'),
('Grace Hopper', 'Americana', '1906-12-09', 'Pioneira da computação'),
('Linus Torvalds', 'Finlandesa', '1969-12-28', 'Criador do Linux');

-- Inserir itens
INSERT INTO item (titulo, subtitulo, tipo_item, isbn, data_publicacao, editora, idioma, localizacao) VALUES
('Dom Casmurro', NULL, 'livro', '978-8535909814', '1899-12-01', 'Companhia das Letras', 'Português', 'A1-001'),
('The Art of Computer Programming', 'Volume 1: Fundamental Algorithms', 'livro', '978-0201896831', '1968-01-01', 'Addison-Wesley', 'Inglês', 'B2-045'),
('Harry Potter e a Pedra Filosofal', NULL, 'livro', '978-8532511010', '1997-06-26', 'Rocco', 'Português', 'C3-102'),
('A Hora da Estrela', NULL, 'livro', '978-8520925010', '1977-01-01', 'Rocco', 'Português', 'A1-015'),
('Introduction to Algorithms', NULL, 'livro', '978-0262033848', '2009-07-31', 'MIT Press', 'Inglês', 'B2-067'),
('Clean Code', 'A Handbook of Agile Software Craftsmanship', 'livro', '978-0132350884', '2008-08-01', 'Pearson', 'Inglês', 'B2-089'),
('O Cortiço', NULL, 'livro', '978-8508133729', '1890-01-01', 'Ática', 'Português', 'A1-032'),
('Design Patterns', 'Elements of Reusable Object-Oriented Software', 'livro', '978-0201633610', '1994-10-21', 'Addison-Wesley', 'Inglês', 'B2-123');

-- Relacionar itens com autores
INSERT INTO item_autor (id_item, id_autor, tipo_contribuicao) VALUES
(1, 1, 'autor'),
(2, 2, 'autor'),
(3, 3, 'autor'),
(4, 4, 'autor'),
(8, 2, 'autor');

-- Relacionar itens com categorias
INSERT INTO item_categoria (id_item, id_categoria) VALUES
(1, 2), -- Dom Casmurro - Literatura
(2, 1), -- The Art of Computer Programming - Tecnologia
(3, 2), -- Harry Potter - Literatura
(4, 2), -- A Hora da Estrela - Literatura
(5, 1), -- Introduction to Algorithms - Tecnologia
(6, 1), -- Clean Code - Tecnologia
(7, 2), -- O Cortiço - Literatura
(8, 1); -- Design Patterns - Tecnologia

-- Inserir usuários
INSERT INTO usuario (nome, email, tipo_usuario) VALUES
('João Silva', 'joao.silva@email.com', 'estudante'),
('Maria Santos', 'maria.santos@email.com', 'professor'),
('Pedro Oliveira', 'pedro.oliveira@email.com', 'funcionario'),
('Ana Costa', 'ana.costa@email.com', 'estudante'),
('Carlos Mendes', 'carlos.mendes@email.com', 'professor'),
('Lucia Ferreira', 'lucia.ferreira@email.com', 'estudante'),
('Roberto Lima', 'roberto.lima@email.com', 'funcionario'),
('Fernanda Alves', 'fernanda.alves@email.com', 'estudante');

-- Inserir alguns empréstimos
INSERT INTO emprestimo (id_usuario, id_item, data_emprestimo, data_devolucao_prevista, status) VALUES
(1, 1, '2025-06-15', '2025-07-15', 'ativo'),
(2, 2, '2025-06-20', '2025-07-20', 'ativo'),
(3, 5, '2025-06-25', '2025-07-25', 'ativo'),
(4, 3, '2025-06-01', '2025-07-01', 'devolvido'),
(5, 6, '2025-06-10', '2025-07-10', 'ativo');

-- Inserir algumas reservas
INSERT INTO reserva (id_usuario, id_item, data_reserva, data_expiracao, status) VALUES
(6, 1, '2025-07-01', '2025-07-08', 'ativa'),
(7, 2, '2025-07-02', '2025-07-09', 'ativa'),
(8, 5, '2025-07-03', '2025-07-10', 'ativa');


-- CONSULTAS DE EXEMPLO


-- Buscar livros disponíveis por categoria
SELECT 
    i.titulo,
    i.subtitulo,
    a.nome as autor,
    c.nome as categoria,
    i.editora,
    i.localizacao
FROM item i
JOIN item_autor ia ON i.id_item = ia.id_item
JOIN autor a ON ia.id_autor = a.id_autor
JOIN item_categoria ic ON i.id_item = ic.id_item
JOIN categoria c ON ic.id_categoria = c.id_categoria
WHERE i.disponivel = TRUE 
    AND c.nome = 'Literatura'
ORDER BY i.titulo;

-- Verificar empréstimos ativos de um usuário
SELECT 
    u.nome as usuario,
    i.titulo,
    e.data_emprestimo,
    e.data_devolucao_prevista,
    CASE 
        WHEN e.data_devolucao_prevista < CURRENT_DATE THEN 'ATRASADO'
        ELSE 'EM DIA'
    END as situacao
FROM emprestimo e
JOIN usuario u ON e.id_usuario = u.id_usuario
JOIN item i ON e.id_item = i.id_item
WHERE u.email = 'joao.silva@email.com' 
    AND e.status = 'ativo'
ORDER BY e.data_devolucao_prevista;

-- Relatório de empréstimos por tipo de usuário
SELECT 
    u.tipo_usuario,
    COUNT(e.id_emprestimo) as total_emprestimos,
    COUNT(CASE WHEN e.status = 'ativo' THEN 1 END) as emprestimos_ativos,
    COUNT(CASE WHEN e.status = 'devolvido' THEN 1 END) as emprestimos_devolvidos
FROM usuario u
LEFT JOIN emprestimo e ON u.id_usuario = e.id_usuario
GROUP BY u.tipo_usuario
ORDER BY total_emprestimos DESC;

-- Buscar itens por autor
SELECT 
    a.nome as autor,
    i.titulo,
    i.tipo_item,
    i.data_publicacao,
    i.editora
FROM autor a
JOIN item_autor ia ON a.id_autor = ia.id_autor
JOIN item i ON ia.id_item = i.id_item
WHERE a.nome ILIKE '%Machado%'
ORDER BY i.data_publicacao;

-- Verificar reservas pendentes
SELECT 
    u.nome as usuario,
    i.titulo,
    r.data_reserva,
    r.data_expiracao,
    r.status
FROM reserva r
JOIN usuario u ON r.id_usuario = u.id_usuario
JOIN item i ON r.id_item = i.id_item
WHERE r.status = 'ativa'
    AND r.data_expiracao >= CURRENT_DATE
ORDER BY r.data_reserva;

-- Estatísticas gerais do sistema
SELECT 
    'Usuários' as categoria,
    COUNT(*) as total
FROM usuario
WHERE status = TRUE
UNION ALL
SELECT 
    'Itens no Acervo' as categoria,
    COUNT(*) as total
FROM item
UNION ALL
SELECT 
    'Empréstimos Ativos' as categoria,
    COUNT(*) as total
FROM emprestimo
WHERE status = 'ativo'
UNION ALL
SELECT 
    'Reservas Ativas' as categoria,
    COUNT(*) as total
FROM reserva
WHERE status = 'ativa';


-- VIEWS ÚTEIS


-- View para consulta completa de itens
CREATE VIEW v_itens_completos AS
SELECT 
    i.id_item,
    i.titulo,
    i.subtitulo,
    i.tipo_item,
    i.isbn,
    i.data_publicacao,
    i.editora,
    i.localizacao,
    i.disponivel,
    STRING_AGG(DISTINCT a.nome, ', ') as autores,
    STRING_AGG(DISTINCT c.nome, ', ') as categorias
FROM item i
LEFT JOIN item_autor ia ON i.id_item = ia.id_item
LEFT JOIN autor a ON ia.id_autor = a.id_autor
LEFT JOIN item_categoria ic ON i.id_item = ic.id_item
LEFT JOIN categoria c ON ic.id_categoria = c.id_categoria
GROUP BY i.id_item, i.titulo, i.subtitulo, i.tipo_item, i.isbn, 
         i.data_publicacao, i.editora, i.localizacao, i.disponivel;

-- View para empréstimos ativos
CREATE VIEW v_emprestimos_ativos AS
SELECT 
    e.id_emprestimo,
    u.nome as usuario,
    u.email,
    u.tipo_usuario,
    i.titulo,
    i.tipo_item,
    e.data_emprestimo,
    e.data_devolucao_prevista,
    CASE 
        WHEN e.data_devolucao_prevista < CURRENT_DATE THEN 'ATRASADO'
        ELSE 'EM DIA'
    END as situacao,
    CURRENT_DATE - e.data_devolucao_prevista as dias_atraso
FROM emprestimo e
JOIN usuario u ON e.id_usuario = u.id_usuario
JOIN item i ON e.id_item = i.id_item
WHERE e.status = 'ativo';


-- FUNÇÕES ÚTEIS


-- Função para calcular multa por atraso
CREATE OR REPLACE FUNCTION calcular_multa(
    p_data_devolucao_prevista DATE,
    p_data_atual DATE DEFAULT CURRENT_DATE
) RETURNS DECIMAL(10,2) AS $$
DECLARE
    dias_atraso INTEGER;
    valor_multa DECIMAL(10,2);
BEGIN
    dias_atraso := p_data_atual - p_data_devolucao_prevista;
    
    IF dias_atraso <= 0 THEN
        RETURN 0.00;
    ELSE
        -- R$ 1,00 por dia de atraso
        valor_multa := dias_atraso * 1.00;
        RETURN valor_multa;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para verificar disponibilidade de item
CREATE OR REPLACE FUNCTION verificar_disponibilidade(p_id_item INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    item_disponivel BOOLEAN;
BEGIN
    SELECT disponivel INTO item_disponivel
    FROM item
    WHERE id_item = p_id_item;
    
    RETURN COALESCE(item_disponivel, FALSE);
END;
$$ LANGUAGE plpgsql;


-- PROCEDIMENTOS ARMAZENADOS


-- Procedimento para realizar empréstimo
CREATE OR REPLACE FUNCTION realizar_emprestimo(
    p_id_usuario INTEGER,
    p_id_item INTEGER,
    p_dias_emprestimo INTEGER DEFAULT 30
) RETURNS TABLE(
    sucesso BOOLEAN,
    mensagem TEXT,
    id_emprestimo INTEGER
) AS $$
DECLARE
    v_disponivel BOOLEAN;
    v_id_emprestimo INTEGER;
    v_data_devolucao DATE;
BEGIN
    -- Verificar se o item está disponível
    SELECT disponivel INTO v_disponivel
    FROM item
    WHERE id_item = p_id_item;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Item não encontrado', NULL::INTEGER;
        RETURN;
    END IF;
    
    IF NOT v_disponivel THEN
        RETURN QUERY SELECT FALSE, 'Item não está disponível', NULL::INTEGER;
        RETURN;
    END IF;
    
    -- Calcular data de devolução
    v_data_devolucao := CURRENT_DATE + p_dias_emprestimo;
    
    -- Inserir empréstimo
    INSERT INTO emprestimo (id_usuario, id_item, data_devolucao_prevista)
    VALUES (p_id_usuario, p_id_item, v_data_devolucao)
    RETURNING id_emprestimo INTO v_id_emprestimo;
    
    -- Atualizar disponibilidade do item
    UPDATE item SET disponivel = FALSE WHERE id_item = p_id_item;
    
    RETURN QUERY SELECT TRUE, 'Empréstimo realizado com sucesso', v_id_emprestimo;
END;
$$ LANGUAGE plpgsql;


-- COMENTÁRIOS NAS TABELAS


COMMENT ON TABLE usuario IS 'Tabela de usuários do sistema';
COMMENT ON TABLE item IS 'Tabela de itens do acervo (livros, artigos, etc.)';
COMMENT ON TABLE emprestimo IS 'Tabela de controle de empréstimos';
COMMENT ON TABLE reserva IS 'Tabela de reservas de itens';
COMMENT ON TABLE historico_acoes IS 'Tabela de auditoria do sistema';

